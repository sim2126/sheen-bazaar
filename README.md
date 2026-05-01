# Sheen Bazaar

A full-stack mobile marketplace for authentic Kashmiri handicrafts — connecting artisan shop owners directly with customers, with an AI layer for discovery and product storytelling.

**Developed by:** Hakim Mohammad Iisa  
**Institution:** Manipal University Jaipur  
**Stack:** Flutter · Firebase (Auth, Firestore, Storage, Cloud Functions) · Gemini 2.5 Flash · Provider

---

## Table of Contents

1. [Splash & Authentication](#1-splash--authentication)
2. [Customer Experience](#2-customer-experience)
3. [Vendor Experience](#3-vendor-experience)
4. [Admin Panel](#4-admin-panel)
5. [AI Features](#5-ai-features)
6. [Tech Stack](#6-tech-stack)
7. [Firebase Schema](#7-firebase-schema)
8. [Project Structure](#8-project-structure)
9. [Getting Started](#9-getting-started)
10. [Future Scope](#10-future-scope)
11. [License](#11-license)
12. [Author](#12-author)

---

## 1. Splash & Authentication

The app opens to a full-screen hero with a falling-leaves Lottie animation and sequenced text reveals — "Sheen Bazaar" fades in left to right, followed by a gold divider and the tagline. No login wall: guests land directly on the browse screen. A hamburger menu in the top corner gives access to search, cart, orders, the AI assistant, and sign in.

![Splash Screen](screenshots/SplashScreenHome.jpg)

New users register by choosing a role — Customer or Artisan (Shop Owner) — alongside their name, phone, email, and password. Existing users log straight in. After login, the app routes each role to their respective home: admin to the Admin Panel, shop owners to their dashboard, customers back to browsing.

![Login](screenshots/LogInScreen.jpg)

![Register](screenshots/RegisterScreen.jpg)

---

## 2. Customer Experience

### Browsing

The home screen presents 13 Kashmiri handicraft categories — Copper Ware, Papier Mache, Silverware, Enamelware, Terracotta, Green Serpentine, Coins, Shawls, Jewellery, Carpets, Willow Wicker, Woodwork, and Brass Ware — as full-width editorial cards with staggered entrance animations. Each category card carries a cover image, name, description, and an "Explore Collection" prompt.

![Categories](screenshots/CategoriesScreen.jpg)

Selecting a category shows all shops that carry in-stock products in that category. This is resolved via a Firestore collectionGroup query on products — not a shop-level tag — so a shop appears in every category it stocks. Each shop card shows the cover image, name, location, rating, verified artisan badge, and open/closed status.

![Shops List](screenshots/ShopsScreen.jpg)

Entering a shop reveals the full storefront: cover image header, logo, rating, total reviews, an "Our Story" description section, a product grid, and customer reviews.

![Shop Page](screenshots/ShopPage.jpg)

### Product Detail

Products with AI-generated descriptions display a structured view: a punchy tagline, a narrative craft box with a left terracotta border, and a spec grid covering material, craft technique, colour, dimensions, occasion, and care instructions. The product image is tappable for a full-screen zoom via PhotoView. Products without AI descriptions fall back to a plain description with category and location.

![Product Page](screenshots/ProductPage.jpg)

### Cart & Orders

Multiple products from different shops can be added to a single cart. On checkout, one order document is created per shop automatically — a cart spanning three shops produces three separate orders. Orders move through four stages: Placed, Confirmed, Dispatched, and Delivered, each visualised on a progress timeline. Completed orders prompt a review.

![Cart](screenshots/MyCartScreen.jpg)

![My Orders](screenshots/MyOrdersScreen.jpg)

---

## 3. Vendor Experience

Shop owners land on a dashboard showing their shop's cover image, logo, location, live rating, and an open/closed toggle. Navigation tiles lead to product management, incoming orders, and analytics.

![Shop Owner Dashboard](screenshots/ShopOwnerDashboard.jpg)

### Adding Products

The Add Product form collects fields in this order: category (from the 13 canonical categories), product name, price and stock side by side, product image, and description. A sparkle button next to the description field triggers AI generation — Gemini analyses the uploaded image, product name, and selected category, then returns a structured description covering all spec fields. If no image is attached, the generator falls back to text-only using the product name and category.

![Add Product — Form](screenshots/AddProductScreen1.jpg)

![Add Product — AI Description](screenshots/AddProductScreen2.jpg)

### Analytics

The analytics screen shows all-time and current-month revenue, a best-sellers list ranked by units sold, and a low-stock alert panel for products with three or fewer units remaining.

![Shop Owner Analytics](screenshots/ShopOwnerAnalyticsScreen.jpg)

---

## 4. Admin Panel

Admins access a dashboard with three live counters — total shops, orders, and users — fed by real-time Firestore streams. Navigation tiles lead to dedicated management screens.

**Shops** — Every shop is listed with logo, name, location, and verification status. Admins can ban or unban a shop, grant or revoke the verified artisan badge, and browse a shop's product list inline.

**Orders** — A full cross-shop order feed sorted by most recent, with colour-coded status badges: orange (Placed), blue (Confirmed), purple (Dispatched), green (Delivered).

**Users** — All registered users with role badges (Admin, Vendor, Customer), email, phone, and join date.

**Seed categories** — A utility button re-populates the 13 canonical categories in Firestore with correct names, asset image paths, and sort order. Requires confirmation before running.

![Admin Panel](screenshots/AdminPannelScreen.jpg)

---

## 5. AI Features

### AI Shopping Assistant

The chat interface connects to Gemini 2.5 Flash hosted entirely in a Firebase Cloud Function — the API key never touches the device. The function implements context caching: on the first request it fetches the full live product catalog from Firestore, combines it with the system prompt, and caches the result in Gemini for one hour. Subsequent messages within that window skip the catalog re-fetch and pay only for new tokens.

The assistant recommends specific products with shop name and price, and stays strictly within the bounds of the live catalog — it will not invent products.

**Example queries:**
> "I want a traditional Kashmiri gift under ₹2000"  
> "Show me pashmina shawls"  
> "What wooden crafts do you have?"

### AI Description Generator

When a vendor adds a product, a sparkle button sits beside the description field. Tapping it sends the product image (as base64), name, and category to a Gemini Vision Cloud Function. The model returns a JSON object with eight structured fields — tagline, narrative, material, craft technique, colour, dimensions, occasion, and care instructions — which the app parses and renders as a rich product detail view.

---

## 6. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), Material 3 |
| State management | Provider (`CartProvider`) |
| Database | Cloud Firestore |
| Authentication | Firebase Authentication (Email/Password) |
| File storage | Firebase Storage |
| Serverless | Firebase Cloud Functions (Node.js 20, asia-south1) |
| AI model | Google Gemini 2.5 Flash |
| AI key management | Google Secret Manager (`GEMINI_KEY`) |
| Fonts | Playfair Display (headings), Nunito (body) via Google Fonts |
| Animation | Lottie (homepage hero), custom AnimationController (card entrances) |
| Image zoom | photo_view |

---

## 7. Firebase Schema

### `categories/{categoryId}`
```
name        : String
image       : String   — asset path e.g. 'assets/images/category-covers/Copperware.jpeg'
icon        : String   — currently empty
description : String
sortOrder   : int      — 0–12, controls display order on home screen
```

### `users/{userId}`
```
name      : String
email     : String
phone     : int        — stored as integer; always call .toString() before displaying
role      : String     — 'customer' | 'shop_owner' | 'admin'
createdAt : Timestamp
```

### `shops/{shopId}`
```
shopName     : String
description  : String
location     : String
coverImage   : String  — Firebase Storage URL
logo         : String  — Firebase Storage URL
ownerId      : String  — Firebase Auth UID
isOpen       : bool
isVerified   : bool
rating       : double
totalReviews : int
createdAt    : Timestamp

Note: shops do NOT have a categoryId field.
Categories are associated with products, not shops.
```

### `shops/{shopId}/products/{productId}`
```
name        : String
description : String
image       : String   — Firebase Storage URL
price       : double
stock       : int
categoryId  : String   — one of the 13 canonical category IDs
createdAt   : Timestamp
details     : Map?     — present only when AI generation was used
  tagline   : String
  narrative : String
  material  : String
  craft     : String
  color     : String
  dimensions: String
  occasion  : String
  care      : String
```

### `shops/{shopId}/reviews/{reviewId}`
```
userId    : String
userName  : String
rating    : int        — 1 to 5
comment   : String
createdAt : Timestamp
```

### `orders/{orderId}`
```
userId    : String   — Firebase Auth UID
shopId    : String
items     : List     — [{ productId, name, price, quantity, image }]
total     : double
status    : String   — 'placed' | 'confirmed' | 'dispatched' | 'delivered'
createdAt : Timestamp

Note: one order document is created per shop on checkout.
A cart with items from three shops produces three order documents.
```

---

## 8. Project Structure

```
sheen_bazaar/
├── lib/
│   ├── main.dart                          App entry, Firebase init, theme, Provider
│   ├── app_router.dart                    Auth-aware cold-start router (zero visual flash)
│   ├── models/
│   │   ├── category_model.dart
│   │   ├── shop_model.dart
│   │   └── product_model.dart             Includes ProductDetails (AI-generated struct)
│   ├── providers/
│   │   └── cart_provider.dart             Global cart state
│   ├── services/
│   │   ├── category_service.dart          Fetches categories ordered by sortOrder
│   │   ├── shop_service.dart              collectionGroup queries for category browsing
│   │   ├── gemini_service.dart            Proxy to Cloud Functions — chat + vision
│   │   ├── image_upload_service.dart      Validate, resize, upload to Firebase Storage
│   │   └── category_seeder.dart          Calls seedCategories Cloud Function
│   ├── theme/
│   │   └── app_theme.dart                AppColors, AppTextStyles, AppDecorations
│   ├── utils/
│   │   └── transitions.dart              fadeSlideRoute — 320ms cubic page transition
│   ├── widgets/
│   │   ├── hamburger_menu.dart            Full-screen animated menu overlay
│   │   ├── image_picker_field.dart        Reusable image picker with preview
│   │   ├── login_required_dialog.dart     Bottom sheet for guest-gated actions
│   │   └── bottom_nav_bar.dart
│   └── screens/
│       ├── auth/
│       │   └── login_page.dart            Login + Register with role selector
│       ├── customer/
│       │   ├── customer_home.dart         Hero, Lottie animation, category grid
│       │   ├── search_screen.dart         Search input with suggestion chips
│       │   ├── search_results_screen.dart collectionGroup results, out-of-stock dimmed
│       │   ├── shops_list.dart            Shops per category (editorial cards)
│       │   ├── shop_detail.dart           Products grid + reviews section
│       │   ├── product_detail.dart        AI/plain description, cart CTA, image zoom
│       │   ├── cart_screen.dart           Item list, qty controls, per-shop checkout
│       │   ├── cart_icon_button.dart      Badge icon for app bars
│       │   ├── order_history.dart         Status timeline per order
│       │   ├── ai_assistant.dart          Gemini chat with context caching
│       │   └── write_review.dart          5-star review form
│       ├── shop_owner/
│       │   ├── shop_dashboard.dart        Overview, stats, navigation
│       │   ├── create_shop.dart           Create/edit shop with image uploads
│       │   ├── manage_products.dart       Product list + Add/Edit form + AI generate
│       │   ├── vendor_orders.dart         Order feed with status update
│       │   └── vendor_analytics.dart      Revenue, best sellers, low-stock alerts
│       └── admin/
│           ├── admin_panel.dart           Live counters, navigation tiles
│           ├── admin_shops.dart           Ban/verify shops, browse products
│           ├── admin_users.dart           User list with role badges
│           └── admin_orders.dart          Cross-shop order feed
├── functions/
│   ├── index.js                           geminiChat, geminiDescribeProduct, seedCategories
│   └── package.json
├── assets/
│   ├── images/
│   │   ├── splash_bg.jpg
│   │   ├── wicker_basket.png
│   │   └── category-covers/              13 JPEG files, one per category
│   └── lottie/
│       └── Falling leaves.json
├── docs/
│   └── Summary-sheen-bazaar-first-build.md
├── firestore.rules
├── firestore.indexes.json
├── firebase.json
└── pubspec.yaml
```

---

## 9. Getting Started

### Prerequisites
- Flutter SDK 3.x or above
- Android Studio or VS Code with Flutter extension
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Authentication, Firestore, Storage, and Cloud Functions enabled
- A Google AI Studio API key for Gemini

### Steps

**1. Clone and install**
```bash
git clone https://github.com/HakimIisa/sheen-bazaar.git
cd sheen-bazaar
flutter pub get
```

**2. Firebase setup**
- Download `google-services.json` from your Firebase project and place it in `android/app/`
- Run `flutterfire configure` to generate `lib/firebase_options.dart`
- Deploy Firestore rules and indexes:
```bash
firebase deploy --only firestore
```

**3. Set the Gemini API key**

The key is stored in Google Secret Manager — it never enters the Flutter app.
```bash
firebase functions:secrets:set GEMINI_KEY
# Paste your Google AI Studio key when prompted
```

**4. Deploy Cloud Functions**
```bash
cd functions
npm install
firebase deploy --only functions
```

**5. Seed categories**

Log in as an admin and tap **Seed Categories** in the Admin Panel. This populates the 13 canonical Kashmiri handicraft categories with correct names, sort order, and asset image paths.

To set an account as admin:
1. Register through the app normally
2. Open Firebase Console → Firestore → `users` → find your document
3. Change `role` from `"customer"` to `"admin"`
4. Log out and log back in

**6. Run**
```bash
flutter run
```

**Build a release APK**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 10. Future Scope

- Payment gateway integration (Razorpay / UPI)
- Push notifications for order status updates
- Augmented Reality product preview
- Multilingual support — Urdu, Hindi, Kashmiri
- AI-powered "You might also like" cross-product recommendations
- Geo-based artisan discovery (map view)

---

## 11. License

© 2026 Hakim Mohammad Iisa. All rights reserved.

This project was developed as an academic major project at Manipal University Jaipur. No part of this repository may be copied, modified, or distributed without the express written permission of the author.

---

## 12. Author

**Hakim Mohammad Iisa**  
B.Tech Computer Science, Manipal University Jaipur

Sheen Bazaar is a personal project rooted in a belief that Kashmir's craft heritage deserves a platform that matches its richness — not a generic marketplace template, but something that carries the same weight as the crafts themselves.
