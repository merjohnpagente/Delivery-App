# Bings — Food Delivery App (Flutter)

A food delivery app UI built in Flutter, based on the
[Food Delivery App UI Design in Flutter](https://www.patreon.com/DearProgrammer/shop/food-delivery-app-ui-design-in-flutter-202135)
design. All image assets are bundled in `assets/images/`.

## Screens

| Screen | File |
|--------|------|
| Splash / Onboarding | `lib/screens/splash_screen.dart` |
| Home (search, categories, food grid) | `lib/screens/home_screen.dart` |
| Food Detail (rating, quantity, add to cart) | `lib/screens/food_detail_screen.dart` |
| Cart (stepper, totals, checkout) | `lib/screens/cart_screen.dart` |
| Profile | `lib/screens/profile_screen.dart` |

## Project structure

```
lib/
├── main.dart                  # App entry, theme, CartProvider
├── models/
│   ├── food_item.dart         # FoodItem + CartItem
│   ├── category.dart          # Category
│   └── cart_provider.dart     # Cart state (provider)
├── data/
│   └── sample_data.dart       # Categories + food items
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── food_detail_screen.dart
│   ├── cart_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── food_card.dart
    ├── category_chip.dart
    └── cart_item_tile.dart
assets/images/                # 29 bundled images
```

## Getting started

Requirements: [Flutter SDK](https://docs.flutter.dev/get-started/install)
3.2+.

```bash
flutter pub get
flutter run
```

## Dependencies

- `google_fonts` — Poppins typeface
- `provider` — cart state management
- `cupertino_icons` — iOS-style icons
