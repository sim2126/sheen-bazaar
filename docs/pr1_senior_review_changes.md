# PR #1 — Senior Review: Feature Breakdown & Tradeoff Analysis

**PR title:** `feat: 10 production features for vendor and customer experience`  
**Author:** sim2126  
**Opened:** 2026-04-10  
**Branch:** `sim2126:feat/production-features` → `main`  
**Status at time of writing:** Open, not yet merged  
**GitHub link:** https://github.com/HakimIisa/sheen-bazaar/pull/1

---

## Overview

A senior developer forked the repo and submitted a PR adding 10 production-grade features across the customer, vendor, and admin sides. The changes touch 19 files: 4 new screens, 1 new backend service (Firebase Cloud Functions), 2 model changes, and modifications to several existing screens and services.

---

## Part 1 — Existing Features That Were Changed

These are features that already existed in the app but were modified or extended.

---

### 1. AI Assistant (`lib/screens/customer/ai_assistant.dart`)

**What we had:**  
On screen open, the assistant immediately fetched the entire product catalog from Firestore — every shop, every product — and loaded it into a single string that was passed to Claude as context on every message. The loading indicator showed while this happened, blocking the user from chatting.

**What changed:**  
The catalog fetch is now **lazy and intent-based**. Instead of loading everything upfront, the assistant first reads the user's message for signals:
- Category keywords: "pashmina", "shawl", "stole", "wool" → `pashmina`; "papier", "mache", "lacquer", "painted" → `papier_mache`; "wood", "walnut", "carv" → `wood`
- Budget keywords: regex matches patterns like "under ₹2000", "below 3000", "₹500"

Only after detecting category or budget does it fire a targeted Firestore query. If the user's first message gives no signal (e.g. "hi"), the assistant asks a clarifying question instead of fetching products.

The system prompt was also tightened: Claude is now told to keep responses under 150 words, never make up products, and ask exactly one clarifying question when catalog is unavailable.

**Why this matters:**  
Reduces Firestore reads significantly. Previously every chat session fetched potentially hundreds of documents. Now it only fetches when there is intent, and only from relevant shops.

**Known limitation:**  
Only 3 categories are hard-coded. Any shop whose `categoryId` doesn't match those 3 strings will never be surfaced to the AI. Also won't understand natural language like "something warm for winter" without the specific keywords.

---

### 2. Claude Service (`lib/services/claude_service.dart`)

**What we had:**  
A single static method `sendMessage()` that calls the Anthropic API directly from the device using the API key stored in `ApiConfig.claudeApiKey`.

**What changed:**  
A second method `sendMessageWithImage()` was added. It encodes an image as base64 and sends it alongside a text prompt to Claude's vision API. This is used for AI-generated product descriptions — a vendor uploads a photo of their product and Claude generates a structured description (tagline, narrative, material, craft type, dimensions, etc.).

**Important:** This method still calls the Anthropic API **directly from the device** with the hardcoded API key — it does not use the new Cloud Function proxy. This is an inconsistency in the PR (see Security section below).

---

### 3. Cart Screen — Order Data (`lib/screens/customer/cart_screen.dart`)

**What we had:**  
When an order was placed, the document saved to Firestore included `userId`, `shopId`, `status`, `total`, `createdAt`, and `items`.

**What changed:**  
One field was added: `shopName` (taken from the first cart item's shop object). This is needed by the new Order History screen so it can display which shop an order came from without making an extra Firestore lookup.

**Old orders** in Firestore won't have this field, but the Order History screen handles it gracefully with `data['shopName'] ?? 'Shop'`.

---

### 4. Customer Home — App Bar (`lib/screens/customer/customer_home.dart`)

**What we had:**  
For logged-in users: Cart icon + Logout button.  
For guests: Just a profile/login menu.

**What changed:**  
- A **Search icon** was added to the app bar for both guests and logged-in users, navigating to the new `SearchScreen`.
- An **Orders icon** (`receipt_long_outlined`) was added for logged-in users only, navigating to the new `OrderHistory` screen.

---

### 5. Admin Shops (`lib/screens/admin/admin_shops.dart`)

**What we had:**  
Admin could view all shops and toggle their `isOpen` status (ban/unban). The trailing column of each shop list tile had a single "Active"/"Banned" badge.

**What changed:**  
A second button was added below the ban toggle — a **Verified/Verify badge**. Tapping it calls `_toggleVerified()` which writes `isVerified: !currentIsVerified` to Firestore. The badge is styled in gold (`0xFFC9A55A`) when verified, grey when not. No confirmation dialog — the toggle fires immediately.

---

### 6. Shop List & Shop Detail (`lib/screens/customer/shops_list.dart`, `shop_detail.dart`)

**What we had:**  
Shop cards showed basic info — name, location, category. The shop detail page showed products, rating, and description.

**What changed:**  
- Shop cards now display a small gold verified badge icon next to verified shops.
- The shop detail page shows the verified badge more prominently, displays the shop's average star rating, and lists customer reviews below the products section.

---

### 7. Manage Products (`lib/screens/shop_owner/manage_products.dart`)

**What we had:**  
Vendors could see their product list with name, price, and stock count.

**What changed:**  
Inline stock warning icons were added:
- Stock = 0 → red icon, "Out of stock" label
- Stock ≤ 3 → orange icon, "Low stock" label

These appear directly on each product tile so vendors can spot inventory issues at a glance without opening each product.

---

### 8. Shop Dashboard (`lib/screens/shop_owner/shop_dashboard.dart`)

**What we had:**  
Basic vendor dashboard with navigation tiles.

**What changed:**  
An **Analytics** tile was added that navigates to the new `VendorAnalytics` screen.

---

## Part 2 — New Features Added

These are brand new screens and capabilities that did not exist before.

---

### 1. Order History Screen (`lib/screens/customer/order_history.dart`)

A full order tracking screen accessible from the app bar on the home screen.

**What it shows:**
- All past orders for the current user, sorted by newest first (real-time Firestore stream)
- Each order card shows: order ID (first 8 chars), shop name, date, item thumbnails with names/quantities/prices, total, and a status badge
- A **4-step timeline tracker**: Placed → Confirmed → Dispatched → Delivered, with gold progress indicators

**Review prompt:**  
When an order's status is `delivered`, a "Write a Review" button appears at the bottom of the order card, linking to the new `WriteReview` screen.

**Technical note — Firestore index required:**  
The screen queries `orders` with `.where('userId', ...).orderBy('createdAt', descending: true)`. Firestore requires a **composite index** on `(userId ASC, createdAt DESC)` for this query. Without creating this index in the Firebase console, the screen will throw an error for real users. This is not documented in the PR and needs to be done before deploying.

---

### 2. Product Search Screen (`lib/screens/customer/search_screen.dart`)

A full search and filter screen accessible to both guests and logged-in users.

**Features:**
- Text search bar
- Category filter chips (tap to toggle)
- Price range slider
- Results update as filters change

**Technical note:**  
Firestore doesn't support native full-text search. The filtering almost certainly works client-side — fetching products then filtering in memory. This is fine for the current catalog size but will become expensive and slow at scale.

---

### 3. Write Review Screen (`lib/screens/customer/write_review.dart`)

A screen for customers to leave a star rating and text review after delivery.

**Features:**
- 5-star interactive rating
- Optional text comment
- On submit: saves review to `shops/{shopId}/reviews` and recalculates the shop's `rating` and `totalReviews` fields atomically

**Known issue — no duplicate prevention:**  
There is no check to see if the user has already reviewed this order. A customer can submit multiple reviews for the same order, which can inflate or tank a shop's rating. The fix would be to query `reviews` for `orderId == X AND userId == Y` before allowing a write, or to record `reviewedOrderIds` on the user document.

---

### 4. Vendor Analytics Dashboard (`lib/screens/shop_owner/vendor_analytics.dart`)

A dedicated analytics screen for vendors accessible from the shop dashboard.

**What it shows:**
- Total orders (all-time and current month)
- Total revenue (all-time and current month)
- Best-selling products
- Low stock alerts (products with stock ≤ 3 or stock = 0)

Data is fetched directly from Firestore on screen load (not real-time stream, which is appropriate for an analytics view).

---

### 5. Firebase Cloud Function Proxy (`functions/index.js`)

A new Node.js Firebase Cloud Function (`claudeProxy`) that proxies Claude API calls from the backend.

**Why this exists:**  
Previously the Claude API key was hardcoded in `ApiConfig.claudeApiKey` and shipped inside the APK. Anyone who decompiles the APK can extract the key and use it at the app owner's expense.

**How it works:**
- Flutter calls the function via Firebase's callable functions SDK
- The function checks that the caller is authenticated (no anonymous AI calls allowed)
- The API key is stored in Firebase Functions config (`functions:config:set anthropic.key=...`) — never in code or the APK
- Region is set to `asia-south1` (Mumbai), closest to Kashmir/India for low latency

**Setup required after merging:**
```bash
cd functions && npm install
firebase deploy --only functions
firebase functions:config:set anthropic.key="YOUR_CLAUDE_API_KEY"
```

**Inconsistency:**  
The existing `sendMessageWithImage()` method in `claude_service.dart` was added in this same PR but still calls the Anthropic API directly from the device. The proxy only protects the chat assistant, not the AI product description generation.

---

### 6. Structured AI Product Descriptions (model + UI)

**Model change (`lib/models/product_model.dart`):**  
A new `ProductDetails` class was added with optional fields: `tagline`, `narrative`, `material`, `craft`, `color`, `dimensions`, `occasion`, `care`. These are stored in Firestore as a `details` map on each product document.

Old products without this field are handled gracefully — `details` is null and the UI falls back to the plain `description` string.

**UI change (`lib/screens/customer/product_detail.dart`):**  
The product detail screen was updated to display the structured description if available: a tagline at the top, a narrative paragraph, and a spec grid (material, dimensions, etc.). A vendor can trigger AI generation from the product edit screen — Claude analyzes the product image and returns JSON that populates these fields.

---

### 7. Product Image Zoom (`lib/screens/customer/product_detail.dart`)

The product hero image now supports **pinch-to-zoom** using the `photo_view` package (`^0.15.0` added to `pubspec.yaml`). Previously the image was a static `Image.network` widget with no interactivity.

---

### 8. Verified Artisan Badge System (`lib/models/shop_model.dart`)

A new `isVerified` boolean field (defaults to `false`) was added to `ShopModel`. The field is toggled by admin and displayed across the app:
- Shop list cards: small gold verified icon
- Shop detail page: prominent badge near the shop name

---

## Part 3 — Summary of What Needs to Be Done Before / After Merging

| Action | Priority | Who |
|---|---|---|
| Create Firestore composite index: `orders (userId ASC, createdAt DESC)` | **Critical** — app will error without it | Developer |
| Add duplicate review prevention to `write_review.dart` | High — data integrity risk | Developer |
| Move `sendMessageWithImage` to use the Cloud Function proxy, not direct API | High — API key still on-device | Developer |
| `flutter pub get` after merge (adds `photo_view`) | Required | Developer |
| `firebase deploy --only functions` | Required for AI chat | Developer |
| `firebase functions:config:set anthropic.key=YOUR_KEY` | Required for AI chat | Developer |
| Expand category detection in AI assistant beyond 3 hard-coded strings | Medium — limits AI usefulness | Developer |

---

*Document created: 2026-04-10. Based on review of PR #1 diff before merging.*
