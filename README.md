# Bings — Food Delivery App (Flutter + Firebase)

A full-stack food delivery app built in Flutter with a Firebase backend
(Firestore, Auth, Storage), based on the
[Food Delivery App UI Design in Flutter](https://www.patreon.com/DearProgrammer/shop/food-delivery-app-ui-design-in-flutter-202135)
design. All image assets are bundled in `assets/images/`.

Firebase project: **bings-828e1** · Android package: **com.bings.app**

## Screens

| Screen | File |
|--------|------|
| Splash / Onboarding | `lib/screens/splash_screen.dart` |
| Login / Register / Forgot password | `lib/screens/auth/` |
| Home (search, categories, food grid) | `lib/screens/home_screen.dart` |
| Food Detail (rating, quantity, add to cart) | `lib/screens/food_detail_screen.dart` |
| Cart (stepper, totals) | `lib/screens/cart_screen.dart` |
| Checkout (address, payment, place order) | `lib/screens/checkout_screen.dart` |
| Orders (order history) | `lib/screens/orders_screen.dart` |
| Profile (user data, logout) | `lib/screens/profile_screen.dart` |

## Project structure

```
lib/
├── main.dart                  # Firebase init, providers, AuthGate
├── firebase_options.dart      # Firebase config (bings-828e1)
├── models/
│   ├── food_item.dart         # FoodItem + CartItem (+ Firestore mapping)
│   ├── category.dart          # Category
│   ├── cart_provider.dart     # Cart state (provider)
│   ├── order.dart             # Order + OrderItem (Firestore mapping)
│   └── user_model.dart        # AppUser (Firestore mapping)
├── providers/
│   ├── auth_provider.dart     # Auth state management
│   └── food_provider.dart     # Firestore menu data (+ offline fallback)
├── services/
│   ├── auth_service.dart      # Login, register, Google sign-in, logout
│   ├── firestore_service.dart # Foods, categories, orders CRUD
│   └── storage_service.dart   # Image uploads (admin app)
├── data/
│   └── sample_data.dart       # Offline fallback menu data
├── screens/
│   ├── auth/                  # login, register, forgot password
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── food_detail_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── orders_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── food_card.dart
    ├── food_image.dart        # Asset-or-network image
    ├── category_chip.dart
    └── cart_item_tile.dart
assets/images/                # 29 bundled images
android/app/google-services.json  # Firebase Android config
```

## Getting started

Requirements: [Flutter SDK](https://docs.flutter.dev/get-started/install)
3.2+.

```bash
flutter pub get
flutter run
```

## Firebase setup

1. The Firebase project **bings-828e1** is already configured and
   `android/app/google-services.json` is committed.
2. In the [Firebase console](https://console.firebase.google.com), enable:
   - **Authentication** → Email/Password + Google sign-in methods
   - **Firestore Database** → create database
   - **Storage** → get started
3. Firestore collections used by the app:

```
users/{uid}      → uid, name, email, phone?, address?, photoUrl?
categories/{id}  → name, image
foods/{id}       → name, description, price, rating, image, category, deliveryTime
orders/{id}      → userId, items[], total, deliveryFee, status,
                    address, paymentMethod, createdAt
```

Until the `foods` / `categories` collections have documents, the app
shows the bundled sample menu as a fallback.

### Suggested Firestore security rules (dev)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /categories/{id} {
      allow read: if true;
      allow write: if false; // admin app only
    }
    match /foods/{id} {
      allow read: if true;
      allow write: if false; // admin app only
    }
    match /orders/{orderId} {
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Dependencies

- `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`
- `google_sign_in` — Google login
- `google_fonts` — Poppins typeface
- `provider` — state management
- `cupertino_icons` — iOS-style icons
