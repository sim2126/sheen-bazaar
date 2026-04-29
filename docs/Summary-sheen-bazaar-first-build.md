# Sheen Bazaar — First Build Summary

Everything needed to continue development in a new conversation.
Generated: 2026-04-29

---

## 1. What the App Is

**Sheen Bazaar** is a Flutter e-commerce marketplace for authentic Kashmiri handicrafts. It connects artisan shop owners with customers, with an admin layer for platform management. The design mirrors a dark-luxury heritage aesthetic — walnut/cream/terracotta palette, Playfair Display serif headings, Nunito body text, and cinematic staggered animations.

**Firebase project ID:** `sheen-bazaar`
**Cloud Functions region:** `asia-south1`
**Platform:** Android (primary), iOS secondary
**Flutter version:** Current stable (Material 3 / Dart null-safe)

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Database | Cloud Firestore |
| Auth | Firebase Authentication |
| Storage | Firebase Storage |
| Serverless | Firebase Cloud Functions (Node.js 20) |
| AI | Google Gemini 2.5 Flash via Cloud Functions |
| State | Provider (`CartProvider`) |
| Fonts | Google Fonts — Playfair Display + Nunito |
| Key packages | `image_picker`, `photo_view`, `lottie`, `lucide_icons`, `provider`, `cloud_functions` |

AI API key is stored in Google Secret Manager (`GEMINI_KEY`). It is **never in the Flutter app** — all AI calls go through Cloud Functions.

---

## 3. User Roles & Routing

Three roles, stored as `role` field on each Firestore `/users/{uid}` document:

| Role | Value in Firestore | Landing screen |
|---|---|---|
| Customer (default) | `customer` | `CustomerHome` |
| Shop owner / artisan | `shop_owner` | `ShopDashboard` |
| Platform admin | `admin` | `AdminPanel` |
| Guest (not logged in) | — | `CustomerHome` (read-only) |

**`AppRouter`** (`lib/app_router.dart`) reads auth state + Firestore role on cold start and `pushReplacement` to the correct screen with zero visual flash (it renders the same splash background while waiting).

---

## 4. Firestore Data Model

### `/categories/{categoryId}`
```
name:        String
image:       String  (asset path: 'assets/images/category-covers/Copperware.jpeg')
icon:        String  (currently empty)
description: String
sortOrder:   int     (0–12, controls display order)
```
13 canonical categories (no `sculptures`):
`copper_ware`, `papier_mache`, `silverware`, `enamelware`, `terracotta`, `green_serpentine`, `coins`, `shawls`, `jewellery`, `carpets`, `willow_wicker`, `woodwork`, `brassware`

### `/users/{uid}`
```
name:      String
email:     String
phone:     int   ← stored as integer, always call .toString() when displaying
role:      String ('customer' | 'shop_owner' | 'admin')
createdAt: Timestamp
```

### `/shops/{shopId}`
```
shopName:     String
description:  String
location:     String
coverImage:   String  (Firebase Storage URL)
logo:         String  (Firebase Storage URL)
ownerId:      String  (uid)
isOpen:       bool
isVerified:   bool
rating:       double
totalReviews: int
createdAt:    Timestamp
```
**Important:** Shops do NOT have a `categoryId` field. Categories are on products only. A one-time migration (`removeShopCategories` Cloud Function, now deleted) cleaned legacy data.

### `/shops/{shopId}/products/{productId}`
```
name:        String
description: String
image:       String  (Firebase Storage URL)
price:       double
stock:       int
categoryId:  String  (one of the 13 canonical category IDs)
createdAt:   Timestamp
details:     Map?    (AI-generated structured data — see ProductDetails below)
```
`details` map (all fields optional — present only when AI generation was used):
```
tagline, narrative, material, craft, color, dimensions, occasion, care  — all String
```

### `/shops/{shopId}/reviews/{reviewId}`
```
userId:    String
userName:  String
rating:    int  (1–5)
comment:   String
createdAt: Timestamp
```

### `/orders/{orderId}`
```
userId:    String
shopId:    String
items:     List<Map>  [{productId, name, price, quantity, image}]
total:     double
status:    String ('placed' | 'confirmed' | 'dispatched' | 'delivered')
createdAt: Timestamp
```
One order is created **per shop** when a customer checks out — a multi-shop cart creates multiple order documents.

---

## 5. Firestore Indexes (`firestore.indexes.json`)

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": [
    {
      "collectionGroup": "products",
      "fieldPath": "categoryId",
      "indexes": [
        { "order": "ASCENDING", "queryScope": "COLLECTION" },
        { "order": "ASCENDING", "queryScope": "COLLECTION_GROUP" }
      ]
    }
  ]
}
```

The `COLLECTION_GROUP` index on `products.categoryId` is required for the category browsing feature — `ShopService.getShopsByCategory` queries `collectionGroup('products').where('categoryId', isEqualTo: ...)`.

---

## 6. Firestore Security Rules (`firestore.rules`)

Key rules summary:
- **Categories**: public read, admin-only write
- **Users**: signed-in read, owner or admin update, admin delete
- **Shops**: public read, signed-in create, owner or admin update/delete
- **Products** (subcollection): public read, owner create/update, owner or admin delete
- **`/{path=**}/products/{productId}`**: wildcard rule giving public collectionGroup read access (required for cross-shop category + search queries)
- **Reviews**: public read, signed-in create, own review update/delete
- **Orders**: signed-in read (own orders, own shop orders, or admin), signed-in create, shop owner or admin update, admin delete

---

## 7. Cloud Functions (`functions/index.js`)

Three deployed functions, all in `asia-south1`:

### `geminiChat`
- **Purpose:** AI shopping assistant
- **Auth:** Required
- **Input:** `{ systemPrompt: string, messages: [{role, content}] }`
- **Output:** `{ text: string }`
- **Model:** `gemini-2.5-flash`
- **Feature:** Context caching — fetches full product catalog from Firestore, caches it with the system prompt for 1 hour (5-minute refresh buffer). Falls back to regular generation gracefully if catalog is below the 32,768-token minimum.
- **Message format conversion:** Flutter sends `role: 'assistant'`, Gemini expects `role: 'model'` — conversion is in the function.

### `geminiDescribeProduct`
- **Purpose:** AI product description from image
- **Auth:** Required
- **Memory:** 512MB, 60s timeout
- **Input:** `{ systemPrompt, userText, imageBase64?, mediaType? }`
- **Output:** `{ text: string }` — a JSON string the app parses into `ProductDetails`
- **Model:** `gemini-2.5-flash`

### `seedCategories`
- **Purpose:** Admin utility — repopulates the 13 canonical categories
- **Auth:** Required + admin role check
- **Action:** Deletes all existing `/categories` docs, writes 13 new ones with `sortOrder`
- **Output:** `{ count: 13 }`

**Important Gemini model note:** As of April 2026, `gemini-1.5-flash`, `gemini-2.0-flash`, and `gemini-2.0-flash-lite` all return 404 for new API keys. The correct working model is `gemini-2.5-flash`.

**Secret setup:**
```bash
firebase functions:secrets:set GEMINI_KEY
firebase deploy --only functions
```

---

## 8. File Map — Every Source File

```
lib/
├── main.dart                          App entry, theme, Provider setup
├── app_router.dart                    Auth-aware cold-start router
│
├── models/
│   ├── category_model.dart            CategoryModel (id, name, image, description)
│   ├── shop_model.dart                ShopModel (no categoryId)
│   └── product_model.dart             ProductModel + ProductDetails (AI struct)
│
├── providers/
│   └── cart_provider.dart             CartProvider — cart state (add/remove/qty/clear)
│
├── services/
│   ├── category_service.dart          Fetches categories ordered by sortOrder, excludes 'sculptures'
│   ├── shop_service.dart              getShopsByCategory (collectionGroup), getProducts
│   ├── gemini_service.dart            Proxy to Cloud Functions (sendMessage, sendMessageWithImage)
│   ├── image_upload_service.dart      Pick + validate + upload to Storage, returns URL
│   └── category_seeder.dart           Calls seedCategories Cloud Function from admin panel
│
├── theme/
│   └── app_theme.dart                 AppColors, AppTextStyles, AppDecorations
│
├── utils/
│   └── transitions.dart               fadeSlideRoute<T> — 320ms cubic page transition
│
├── widgets/
│   ├── bottom_nav_bar.dart            5-tab nav (unused in current build — hamburger used instead)
│   ├── hamburger_menu.dart            Full-screen animated menu overlay
│   ├── image_picker_field.dart        Reusable image upload field with preview
│   └── login_required_dialog.dart     Bottom sheet prompting login for locked features
│
└── screens/
    ├── auth/
    │   └── login_page.dart            Login + Register (role selector: customer/shop_owner)
    │
    ├── customer/
    │   ├── customer_home.dart         Hero + Lottie animation + category list
    │   ├── search_screen.dart         Search input page (autofocus, suggestion chips)
    │   ├── search_results_screen.dart Results via collectionGroup, in-stock first sort
    │   ├── shops_list.dart            Shops for a category (editorial animated cards)
    │   ├── shop_detail.dart           Shop page: products grid + reviews
    │   ├── product_detail.dart        Product page: image zoom, AI/plain description, cart CTA
    │   ├── cart_screen.dart           Cart: items, qty controls, place order
    │   ├── cart_icon_button.dart      Cart badge icon for app bars
    │   ├── order_history.dart         Order list with status timeline
    │   ├── ai_assistant.dart          Chat UI for Gemini shopping assistant
    │   └── write_review.dart          5-star review form
    │
    ├── shop_owner/
    │   ├── shop_dashboard.dart        Shop overview: stats, edit, products, orders, analytics
    │   ├── create_shop.dart           Create/edit shop form (name, description, location, images)
    │   ├── manage_products.dart       Product list + AddEditProduct form + AI generate button
    │   ├── vendor_orders.dart         Order management with status update dropdown
    │   └── vendor_analytics.dart      Revenue stats, best sellers, low-stock alerts
    │
    └── admin/
        ├── admin_panel.dart           Dashboard: live counts, nav tiles, seed categories
        ├── admin_shops.dart           Shop list: ban/verify/browse products
        ├── admin_users.dart           User list with role badges
        └── admin_orders.dart          All orders across all shops
```

---

## 9. Design System

### Colors (`AppColors`)
| Name | Hex | Usage |
|---|---|---|
| `walnut` | `#20180C` | Primary scaffold background |
| `walnutDeep` | `#1A130A` | Headers, overlays, bottom nav |
| `surface` | `#2A1E0F` | Cards, input fills |
| `terracotta` | `#B57031` | Primary action, buttons |
| `terracottaLight` | `#CA9A56` | Hover states, CTA text |
| `saffron` | `#D4A017` | Prices, verified badges |
| `gold` | `#C9A55A` | Borders, separators |
| `cream` | `#F8E8D2` | Primary text on dark |
| `stone` | `#A68F67` | Secondary/caption text |
| `stoneLight` | `#C4A882` | Lighter captions |
| `border` | `#33F8E8D2` | Subtle borders (cream 20%) |
| `cardBorder` | `#4DC9A55A` | Card borders (gold 30%) |

### Typography
- **Display/Headers:** Playfair Display (serif) — `displayHero` 50px, `displayLarge` 38px, `displayMedium` 28px, `displaySmall` 22px
- **Body:** Nunito (rounded sans) — `bodyLarge` 18px, `bodyMedium` 16px, `bodySmall` 14px
- **UI:** Nunito — `label` 13px bold (1.2 letter-spacing), `caption` 13px, `button` 16px bold
- **Price:** Playfair Display 26px, `saffron` color

### Important theme note
The app uses `Brightness.dark` globally. Any screen that uses a **light/beige background** (`Color(0xFFF5EDE0)`) — specifically the shop owner screens (`manage_products.dart`, `create_shop.dart`, `vendor_orders.dart`) and admin screens — must explicitly set `color: Color(0xFF3D2B1F)` on all `TextFormField`, `TextField`, and `DropdownButton` widgets, because the dark theme defaults to cream text which becomes invisible on beige.

---

## 10. Key Feature Implementations

### Category Browsing (cross-shop)
`ShopService.getShopsByCategory` uses `collectionGroup('products')` — NOT a filter on shops. This was a major architectural fix; shops used to have `categoryId` but it was removed because products belong to multiple categories.

### Product Search
Two-screen flow: `SearchScreen` (input) → `SearchResultsScreen` (results).
Results use `collectionGroup('products').get()` then client-side filter by name/description. Out-of-stock products are shown dimmed at 55% opacity with a "sold out" overlay. Sorted: in-stock first, name matches before description matches, then price ascending.

### AI Shopping Assistant (`AiAssistant`)
Chat screen calling `GeminiService.sendMessage` → `geminiChat` Cloud Function. The function uses context caching: it loads the full product catalog + system prompt once and reuses the cached context for 1 hour. The Dart client tracks `_category` and `_budget` from conversation context and attaches the catalog lazily when context is sufficient.

### AI Product Description (`_AiGenerateButton`)
Sparkle button in the Add Product form. Calls `GeminiService.sendMessageWithImage` → `geminiDescribeProduct`. Returns JSON that gets parsed into `ProductDetails`. If image is available, sends it as base64 alongside product name and category. Falls back to text-only if no image. JSON parse failure falls back to raw text in the description field.

### Cart & Orders
`CartProvider` holds items in memory. On checkout (`CartScreen`), items are grouped by `shopId` and one `Order` document is created per shop. The cart is cleared on success.

### Image Upload
`ImageUploadService.upload` validates type (JPG/PNG) and size (5MB), resizes to max 1024×1024, and uploads to Firebase Storage. Path format: `shops/{shopId}/cover.jpg`, `shops/{shopId}/logo.jpg`, `shops/{shopId}/products/{productId}.jpg`.

---

## 11. Navigation Patterns

- **Guest users** land on `CustomerHome`. They can browse categories → shops → products but cannot add to cart, place orders, chat with AI, or write reviews. Attempting restricted actions shows `LoginRequiredDialog`.
- **Login** (`LoginPage`) supports `returnAfterLogin: true` flag — after login it pops back rather than replacing the stack.
- All screen transitions use `fadeSlideRoute` (320ms, cubic `[0.22, 1, 0.36, 1]` easing).
- The hamburger menu (`HamburgerMenu`) opens as a `showGeneralDialog` overlay with staggered fade/slide animations. It contains: Search, Cart, Orders, AI Assistant, and Sign In/Out.

---

## 12. Known Patterns & Gotchas

1. **Phone numbers are integers in Firestore.** Always call `.toString()` before passing to `Text()`. Found in `admin_users.dart`.

2. **`collectionGroup` queries need two things:** (a) a wildcard security rule `match /{path=**}/products/{productId}` and (b) a `fieldOverrides` entry with `queryScope: "COLLECTION_GROUP"` in `firestore.indexes.json`. Without both, queries throw `failed-precondition`.

3. **Shop owner screen backgrounds are beige (`Color(0xFFF5EDE0)`)**, not walnut. They pre-date the unified dark theme. All form fields on those screens need explicit `color: Color(0xFF3D2B1F)` styling.

4. **Gemini model:** Only `gemini-2.5-flash` works for new API keys as of April 2026. `gemini-1.5-flash`, `gemini-2.0-flash`, `gemini-2.0-flash-lite` all return 404.

5. **`removeShopCategories` Cloud Function:** Was deployed as a one-time migration and then deleted. Do not redeploy it.

6. **`sculptures` category:** Removed from Cloud Function seed list and filtered out in `CategoryService`. If it reappears in Firestore, run Seed Categories from admin panel.

7. **Image picker limits:** `maxWidth: 1024, maxHeight: 1024` is set in `ImageUploadService` to prevent oversized base64 payloads crashing the AI function.

---

## 13. Deployment Commands

```bash
# Deploy Cloud Functions only
firebase deploy --only functions

# Deploy Firestore rules + indexes
firebase deploy --only firestore

# Delete a specific function
firebase functions:delete functionName --region asia-south1 --force

# Set / access Gemini API key
firebase functions:secrets:set GEMINI_KEY
firebase functions:secrets:access GEMINI_KEY

# Run Flutter
flutter run
```

---

## 14. Assets

```
assets/
├── images/
│   ├── splash_bg.jpg              Full-screen hero background
│   ├── wicker_basket.png          Empty state placeholder in manage products
│   └── category-covers/           13 JPEG files, one per category
│       Copperware.jpeg, Papier machie.jpeg, Silverware.jpeg,
│       Enamelware.jpeg, Terracotta.jpeg, Green Serpentine.jpeg,
│       Coins.jpeg, Shawls.jpeg, Jewellery.jpeg, Carpet.jpeg,
│       willow wicker.jpeg, Woodwork.jpeg, Brassware.jpeg
└── lottie/
    └── Falling leaves.json        Homepage hero animation (plays once, max 3s)
```

---

## 15. What Was Built in This First Build Session

In rough chronological order:
- Full auth system (login/register, role-based routing)
- Customer home with Lottie hero and animated category cards
- Category → shops list → shop detail → product detail flow
- Cart (in-memory Provider), checkout, order creation per shop
- Order history with status timeline
- 5-star review system with live rating updates on shop
- AI shopping assistant (Gemini context caching)
- AI product description generation (vision + text)
- Shop owner dashboard, create/edit shop, manage products with AI generate
- Vendor order management and analytics
- Admin panel: live stats, shop management, user management, order view, category seeder
- Search: two-screen flow (input → results via collectionGroup)
- Firestore security rules, indexes, collectionGroup wildcard
- Category architecture fix: categories on products, not shops
- Gemini model migration: from gemini-1.5-flash → gemini-2.5-flash
- One-time migration: removed `categoryId` from all shop documents
