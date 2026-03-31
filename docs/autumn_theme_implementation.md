# Autumn in Kashmir — Theme Overhaul Implementation Guide

> **Goal:** Transform Sheen Bazaar into a premium, culturally-rich boutique app that reflects the warmth, poetry, and colour of Harud (autumn) in Kashmir. Replace generic system emojis with bespoke thematic assets, add a Lottie animation, and lay the groundwork for typography and layout upgrades.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Asset Files](#2-asset-files)
3. [Firestore — Seed Categories](#3-firestore--seed-categories)
4. [pubspec.yaml Changes](#4-pubspecyaml-changes)
5. [File-by-File Code Changes](#5-file-by-file-code-changes)
6. [Remaining / Future Phases](#6-remaining--future-phases)

---

## 1. Prerequisites

Install the following Flutter packages by running these commands in the project root:

```bash
flutter pub add lucide_icons
flutter pub add google_fonts
flutter pub add lottie
```

Expected additions to `pubspec.yaml` dependencies:

```yaml
dependencies:
  lucide_icons: ^0.257.0
  google_fonts: ^8.0.2
  lottie: ^3.3.2
```

---

## 2. Asset Files

### 2.1 Required Files

Place these files at the exact paths shown:

| File | Path | Source |
|---|---|---|
| `chinar_leaf.png` | `assets/images/chinar_leaf.png` | User-provided (real photo of an autumn Chinar leaf) |
| `wicker_basket.png` | `assets/images/wicker_basket.png` | User-provided (photo of a wicker/willow basket) |
| `pinjra_window.png` | `assets/images/pinjra_window.png` | AI-generated (Kashmiri Pinjra Kari wooden lattice window) |
| `Falling leaves.json` | `assets/lottie/Falling leaves.json` | User-downloaded Lottie animation |

> **Note:** The `assets/images/` folder already exists. Create `assets/lottie/` manually.

### 2.2 Asset Usage Map

| Asset | Used As |
|---|---|
| `chinar_leaf.png` | Brand icon on Splash screen & Login page header |
| `wicker_basket.png` | Empty cart state, product image fallback, manage products empty state |
| `pinjra_window.png` | "No shop" empty state on dashboard, shop cover fallback, "no shops" list state |
| `Falling leaves.json` | Lottie animation overlay at the bottom of the Splash screen |

---

## 3. Firestore — Seed Categories

The `CustomerHome` screen reads from the Firestore `categories` collection. This collection must be populated manually via the **Firebase Console**.

Go to: **Firebase Console → Firestore Database → Start collection → ID: `categories`**

Add the following 3 documents:

### Document 1
- **Document ID:** `pashmina`
- **Fields:**
  - `name` (string): `Pashmina`
  - `icon` (string): `🧣`
  - `image` (string): A public image URL, e.g. `https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=400`

### Document 2
- **Document ID:** `papier_mache`
- **Fields:**
  - `name` (string): `Papier Mache`
  - `icon` (string): `🎨`
  - `image` (string): A public image URL, e.g. `https://images.unsplash.com/photo-1594040226829-7f251ab46d80?w=400`

### Document 3
- **Document ID:** `wood`
- **Fields:**
  - `name` (string): `Walnut Wood`
  - `icon` (string): `🪵`
  - `image` (string): A public image URL, e.g. `https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400`

> **Important:** The document IDs `pashmina`, `papier_mache`, and `wood` must match exactly what the product category dropdown in `manage_products.dart` uses.

---

## 4. pubspec.yaml Changes

### 4.1 Add Dependencies (under `dependencies:`)

```yaml
  lucide_icons: ^0.257.0
  google_fonts: ^8.0.2
  lottie: ^3.3.2
```

### 4.2 Register Assets (under `flutter: > assets:`)

```yaml
  assets:
    - assets/images/splash_bg.jpg
    - assets/images/chinar_leaf.png
    - assets/images/wicker_basket.png
    - assets/images/pinjra_window.png
    - assets/lottie/
```

The trailing `/` on `assets/lottie/` registers the entire folder, so all `.json` files inside are bundled automatically.

---

## 5. File-by-File Code Changes

---

### 5.1 `lib/screens/splash_screen.dart`

**Imports to add at top:**
```dart
import 'package:lottie/lottie.dart';
```

**Change 1 — Brand icon (replace scarf emoji with Chinar leaf image)**

Find:
```dart
child: const Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      '🧣',
      style: TextStyle(fontSize: 56),
    ),
```

Replace with:
```dart
child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Image.asset(
      'assets/images/chinar_leaf.png',
      height: 64,
      width: 64,
    ),
```

**Change 2 — Loading indicator (replace spinner with Lottie animation)**

Find:
```dart
// ── Loading indicator at bottom ──
const Positioned(
  bottom: 48,
  left: 0,
  right: 0,
  child: Center(
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        color: Color(0xFFC9A55A),
        strokeWidth: 1.5,
      ),
    ),
  ),
),
```

Replace with:
```dart
// ── Falling leaves Lottie at bottom ──
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: IgnorePointer(
    child: Lottie.asset(
      'assets/lottie/Falling leaves.json',
      height: 260,
      fit: BoxFit.cover,
      repeat: true,
    ),
  ),
),
```

---

### 5.2 `lib/screens/auth/login_page.dart`

**Imports to add at top:**
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

**Change 1 — Brand header icon (replace scarf emoji with Chinar leaf)**

Find:
```dart
child: const Center(
  child: Text(
    '🧣',
    style: TextStyle(
      fontSize: 36,
    ),
  ),
),
```

Replace with:
```dart
child: Center(
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Image.asset(
      'assets/images/chinar_leaf.png',
      color: const Color(0xFFF5EDE0),
    ),
  ),
),
```

**Change 2 — Role chip icons (replace emojis with Lucide icons)**

The `_roleChip` method signature must change from `required String icon` to `required Widget icon`.

Find the method signature:
```dart
Widget _roleChip({
  required String label,
  required String icon,
  required String value,
}) {
```

Replace with:
```dart
Widget _roleChip({
  required String label,
  required Widget icon,
  required String value,
}) {
```

Find the icon rendering inside the chip:
```dart
Text(
  icon,
  style: const TextStyle(
    fontSize: 22,
  ),
),
```

Replace with:
```dart
Theme(
  data: ThemeData(iconTheme: IconThemeData(color: selected ? const Color(0xFFF5EDE0) : const Color(0xFF3D2B1F))),
  child: icon,
),
```

Find the two chip instantiation calls:
```dart
_roleChip(
  label: 'Customer',
  icon: '🛍️',
  value: 'customer',
),
```
Replace `icon: '🛍️'` with `icon: const Icon(LucideIcons.shoppingBag, size: 24)`.

```dart
_roleChip(
  label: 'Artisan / Shop Owner',
  icon: '🧑‍🎨',
  value: 'shop_owner',
),
```
Replace `icon: '🧑‍🎨'` with `icon: const Icon(LucideIcons.palette, size: 24)`.

---

### 5.3 `lib/screens/customer/cart_screen.dart`

**Change 1 — Empty cart state (replace shopping cart emoji with wicker basket image)**

Find:
```dart
const Text(
  '🛒',
  style: TextStyle(fontSize: 64),
),
```

Replace with:
```dart
Image.asset(
  'assets/images/wicker_basket.png',
  height: 110,
),
```

**Change 2 — Empty cart message (more poetic copy)**

Find:
```dart
'Explore the bazaar and add something beautiful.',
```

Replace with:
```dart
'Like a crisp autumn breeze...\nyour cart is currently empty.',
textAlign: TextAlign.center,
// also set height: 1.5 in its TextStyle
```

**Change 3 — Cart item image fallback (replace basket emoji with asset)**

Find:
```dart
child: const Center(
  child: Text(
    '🧺',
    style: TextStyle(fontSize: 28),
  ),
),
```

Replace with:
```dart
child: Center(
  child: Image.asset(
    'assets/images/wicker_basket.png',
    height: 36,
    width: 36,
    color: const Color(0x333D2B1F),
  ),
),
```

---

### 5.4 `lib/screens/shop_owner/shop_dashboard.dart`

**Imports to add:**
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

**Change 1 — No-shop empty state icon (replace store emoji with Pinjra window)**

Find:
```dart
const Text(
  '🏪',
  style: TextStyle(fontSize: 72),
),
```

Replace with:
```dart
Image.asset(
  'assets/images/pinjra_window.png',
  height: 120,
),
```

**Change 2 — No-shop empty state message (more poetic copy)**

Find:
```dart
'Create your shop and start showcasing your crafts to the world.',
```

Replace with:
```dart
'The artisan is resting.\nCreate your shop to open your windows to the bazaar.',
```

**Change 3 — Shop avatar fallback (replace painter emoji with Lucide icon)**

Find:
```dart
? const Text(
    '🧑‍🎨',
    style: TextStyle(fontSize: 22),
  )
```

Replace with:
```dart
? const Icon(
    LucideIcons.user,
    color: Color(0xFFF5EDE0),
    size: 26,
  )
```

**Change 4 — Stat card icons (replace emojis with Lucide icons & asset)**

The `_StatCard` widget's `icon` field type must change from `String` to `Widget`.

Change the class field declaration:
```dart
// from:
final String icon;
// to:
final Widget icon;
```

Change the icon rendering inside the card:
```dart
// from:
Text(icon, style: const TextStyle(fontSize: 22)),
// to:
icon,
```

Then update the three `_StatCard` instantiations:
```dart
// Rating card:
icon: Image.asset('assets/images/chinar_leaf.png', height: 24, width: 24),

// Reviews card:
icon: const Icon(LucideIcons.messageSquare, size: 24, color: Color(0xFF3D2B1F)),

// Status card:
icon: const Icon(LucideIcons.packageOpen, size: 24, color: Color(0xFF3D2B1F)),
```

---

### 5.5 `lib/screens/shop_owner/manage_products.dart`

**Imports to add:**
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

**Change 1 — Empty products state (replace box emoji with wicker basket image)**

Find:
```dart
const Text('📦', style: TextStyle(fontSize: 56)),
```

Replace with:
```dart
Image.asset('assets/images/wicker_basket.png', height: 80),
```

**Change 2 — Product image fallback (replace basket emoji with asset)**

Find:
```dart
child: const Center(child: Text('🧺', style: TextStyle(fontSize: 24))),
```

Replace with:
```dart
child: Center(child: Image.asset('assets/images/wicker_basket.png', height: 28, color: const Color(0x333D2B1F))),
```

**Change 3 — AI generate button icon (replace sparkle emoji with Lucide icon)**

Find:
```dart
: const Text('✨', style: TextStyle(fontSize: 20)),
```

Replace with:
```dart
: const Icon(LucideIcons.sparkles, color: Color(0xFFF5EDE0), size: 20),
```

---

### 5.6 `lib/screens/shop_owner/vendor_orders.dart`

**Change 1 — Empty orders state (replace receipt emoji with wicker basket image)**

Find:
```dart
const Text(
  '🧾',
  style: TextStyle(fontSize: 56),
),
```

Replace with:
```dart
Image.asset(
  'assets/images/wicker_basket.png',
  height: 80,
),
```

---

### 5.7 `lib/screens/customer/shop_detail.dart`

**Imports to add:**
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

**Change 1 — Shop avatar fallback (replace painter emoji with Lucide icon)**

Find:
```dart
? const Text(
    '🧑‍🎨',
    style: TextStyle(fontSize: 22),
  )
```

Replace with:
```dart
? const Icon(
    LucideIcons.user,
    color: Color(0xFFF5EDE0),
    size: 26,
  )
```

**Change 2 — Hero cover fallback (replace store emoji with Pinjra window)**

Find (in `_heroBg()`):
```dart
child: const Center(
  child: Text(
    '🏪',
    style: TextStyle(fontSize: 72, color: Colors.white24),
  ),
),
```

Replace with:
```dart
child: Center(
  child: Image.asset('assets/images/pinjra_window.png', height: 120, color: Colors.white24),
),
```

**Change 3 — Product card image fallback (replace basket emoji with asset)**

Find (in `_imgFallback()` inside `_ProductCard`):
```dart
child: const Center(
  child: Text('🧺', style: TextStyle(fontSize: 40)),
),
```

Replace with:
```dart
child: Center(
  child: Image.asset('assets/images/wicker_basket.png', height: 40, color: const Color(0x333D2B1F)),
),
```

---

### 5.8 `lib/screens/customer/shops_list.dart`

**Change 1 — Empty state (replace store emoji with Pinjra window image)**

Find:
```dart
Text(
  '🏪',
  style: TextStyle(fontSize: 56),
),
SizedBox(height: 16),
Text(
  'No shops open in this category yet',
  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
),
```

Replace with:
```dart
Image.asset(
  'assets/images/pinjra_window.png',
  height: 100,
),
SizedBox(height: 16),
Text(
  'No artisans have opened their windows\nfor this category yet.',
  textAlign: TextAlign.center,
  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, height: 1.5),
),
```

> **Note:** Remove `const` from the parent `Center` widget since `Image.asset` is not const.

**Change 2 — Shop card cover fallback (replace store emoji with Pinjra window)**

Find (in `_fallbackBanner()`):
```dart
child: const Center(
  child: Text('🏪', style: TextStyle(fontSize: 48)),
),
```

Replace with:
```dart
child: Center(
  child: Image.asset(
    'assets/images/pinjra_window.png',
    height: 80,
    color: Colors.white24,
  ),
),
```

---

### 5.9 `lib/screens/customer/product_detail.dart`

**Change 1 — Product image fallback (replace basket emoji with asset)**

Find (in `_imgFallback()`):
```dart
child: const Center(
  child: Text('🧺', style: TextStyle(fontSize: 64)),
),
```

Replace with:
```dart
child: Center(
  child: Image.asset(
    'assets/images/wicker_basket.png',
    height: 64,
    color: Color(0x333D2B1F),
  ),
),
```

---

### 5.10 `lib/screens/admin/admin_panel.dart`

**Imports to add:**
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

**Change 1 — Welcome header (remove hand-wave emoji)**

Find:
```dart
'👋 Welcome, Admin',
```

Replace with:
```dart
'Welcome, Admin',
```

**Change 2 — Stat card type change**

The `_StatCard` `icon` field must change from `String` to `Widget`.

```dart
// from:
final String icon;
// to:
final Widget icon;
```

Change rendering:
```dart
// from:
Text(icon, style: const TextStyle(fontSize: 24)),
// to:
icon,
```

**Change 3 — Stat card icons (replace emojis with Lucide icons)**

```dart
_StatCard(
  label: 'Shops',
  icon: const Icon(LucideIcons.store, size: 24, color: Color(0xFF3D2B1F)),
  ...
),
_StatCard(
  label: 'Orders',
  icon: const Icon(LucideIcons.receipt, size: 24, color: Color(0xFF3D2B1F)),
  ...
),
_StatCard(
  label: 'Users',
  icon: const Icon(LucideIcons.users, size: 24, color: Color(0xFF3D2B1F)),
  ...
),
```

---

### 5.11 `lib/screens/admin/admin_shops.dart`

**Imports to add:**
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

**Change 1 — Shop avatar fallback (replace store emoji with Lucide icon)**

Find:
```dart
? const Text('🏪')
```

Replace with:
```dart
? const Icon(LucideIcons.store, color: Color(0xFF3D2B1F), size: 22)
```

**Change 2 — Product thumbnail fallback (replace basket emoji with asset)**

Find:
```dart
child: const Center(
  child: Text('🧺', style: TextStyle(fontSize: 16)),
),
```

Replace with:
```dart
child: Center(
  child: Image.asset(
    'assets/images/wicker_basket.png',
    height: 24,
    color: const Color(0x553D2B1F),
  ),
),
```

---

### 5.12 `lib/screens/customer/customer_home.dart`

**Imports to add:**
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

**Change 1 — AI Assistant FAB icon (replace sparkle emoji with Lucide icon)**

Find:
```dart
icon: const Text('✨', style: TextStyle(fontSize: 18)),
```

Replace with:
```dart
icon: const Icon(LucideIcons.sparkles, color: Color(0xFFC9A55A), size: 20),
```

---

## 6. Remaining / Future Phases

These were planned but not yet implemented:

### Phase 2 — Poetic Typography (Google Fonts)

In `main.dart`, configure the app's `ThemeData` to use Cormorant Garamond for headings and Lato for body text:

```dart
import 'package:google_fonts/google_fonts.dart';

ThemeData(
  textTheme: GoogleFonts.latoTextTheme().copyWith(
    displayLarge: GoogleFonts.cormorantGaramond(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF3D2B1F),
    ),
    headlineMedium: GoogleFonts.cormorantGaramond(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF3D2B1F),
    ),
  ),
)
```

### Phase 3 — Layout & Visual Warmth

- Add a subtle warm gradient to the `CustomerHome` AppBar background
- Add glassmorphism cards (frosted glass effect) on the Shop Detail screen
- Wrap category grid cards with a Hero widget for smooth page transitions

### Phase 4 — Animations

- Add `PageRouteBuilder` with a fade+slide transition to all Navigator pushes
- Consider a Lottie loading animation for the product grid on `ShopDetail`
- Add subtle scale animation on category card tap using `AnimatedScale`
