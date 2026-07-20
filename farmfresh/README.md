# FarmFresh — Flutter Mobile App

Premium farm-to-home grocery delivery app, built from the approved
`mobile-wireframe.html`. All 13 screens are implemented with a clean,
layered architecture and a design system ported from the wireframe tokens.

Data is currently **mock** (seeded from the wireframe); the real API attaches
by swapping one layer — see [Attaching the API](#attaching-the-api).

## Run

```bash
cd farmfresh
flutter pub get
flutter run          # pick a device (iOS simulator, Android emulator, or Chrome)
```

Verify without a device:

```bash
flutter analyze      # static analysis (clean)
flutter test         # compiles the app + boots to splash
```

## Screens (13)

Splash · Login (phone + OTP) · Home · Auto Kirana List (flagship) · Combo Packs ·
Products · Product Detail · Cart · Checkout · Subscriptions · Repeat Last Month ·
AI Assistant · Profile — plus a 6-tab bottom nav, bottom-sheet modals, light/dark themes.

## Architecture

Clean, layered — dependencies point inward (`presentation → domain ← data`):

```
lib/
  core/                       Cross-cutting: theme, router, design-system widgets
    theme/                    AppColors (ThemeExtension), AppTheme, dimens, theme_controller
    router/                   go_router config (StatefulShellRoute = bottom nav)
    widgets/                  AppCard, AppTag, buttons, BottomSheetShell, ImagePlaceholder, …
  domain/                     Pure Dart — no Flutter imports
    entities/                 Product, Category, ComboPack, KiranaPlan, BasketLine, …
    repositories/             Abstract interfaces (the API seam)
  data/
    datasources/mock_data.dart   Seed data lifted from the wireframe
    repositories/                Mock implementations of the domain interfaces
  presentation/
    providers/                Riverpod: DI, async catalog reads, cart & theme state
    features/<feature>/       One folder per screen (+ its widgets)
    widgets/                  Shared cross-feature widgets (ProductCard)
  app.dart                    MaterialApp.router + themes
  main.dart                   runApp(ProviderScope(...))
```

**State management:** Riverpod. **Navigation:** go_router (each bottom-nav tab
keeps its own stack). **Theming:** brand tokens travel through a `ThemeExtension`
(`context.colors.green`, `context.text`), with full light + dark themes matching
the wireframe.

## Attaching the API

Every backend call lives behind a `domain/repositories` interface. To go live:

1. Add a remote data source (e.g. `data/datasources/remote_*.dart`) using `http`/`dio`.
2. Implement the same repository interface (e.g. `RemoteCatalogRepository implements CatalogRepository`).
3. Override the provider in `main.dart`:

   ```dart
   ProviderScope(
     overrides: [
       catalogRepositoryProvider.overrideWithValue(RemoteCatalogRepository(...)),
       kiranaRepositoryProvider.overrideWithValue(RemoteKiranaRepository(...)),
       assistantRepositoryProvider.overrideWithValue(RemoteAssistantRepository(...)),
     ],
     child: const FarmFreshApp(),
   )
   ```

No UI or provider-consumer code changes. Endpoint mapping is documented in each
repository interface and in the repo-root `PLAN.md` (§5).

> Prices, copy and the brand name ("FarmFresh") are placeholders from the
> wireframe — swap them when real content is available.
