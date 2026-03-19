# Local Setup

## Current expectation

PocketClaw is organized as a Flutter/Dart monorepo.

Expected tools:

- Flutter SDK
- Dart SDK (bundled with Flutter)
- Git

## Bootstrap outline

Once Flutter is available locally:

```bash
flutter --version
dart --version
flutter config --enable-android
cd pocketclaw
dart pub global activate melos
melos bootstrap
```

## Notes

- The repository can be scaffolded and documented without Flutter.
- Full local validation requires Flutter / Dart to be installed.
- CI should become the first consistent validation environment until local toolchains are standardized.
