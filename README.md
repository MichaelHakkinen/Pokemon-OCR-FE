# Pokemon OCR Frontend (Flutter Mobile Client)

Cross-platform iOS & Android mobile application for scanning Pokémon Trading Cards, managing collections, and generating customized CSV exports.

---

## Features
- **Card Viewfinder with 2.5:3.5 Cutout Guide**:
  - `CustomPainter` overlay rendering a 2.5:3.5 (standard Pokémon card ratio) cutout with rounded corners and official Pokémon yellow corner brackets.
  - Native camera controls: Torch / Flashlight toggle, tap-to-focus with visual reticle, and exposure lock.
  - Quick-toggle dropdown for language script hints (`Auto`, `Latin`, `Japanese`, `Indonesian`, `Korean`, `Chinese`).
- **Precise Image Slicing**:
  - `ImageCropperHelper` slices the captured photo precisely to the viewfinder cutout bounds using the pure-Dart `image` package before uploading.
- **Dynamic Pre-Export Survey Modal & CSV Engine**:
  - Global settings switch: **"Show Metadata Popup before CSV Export"**.
  - Dynamic Form Dialog: Dynamically renders inputs based on configured field definitions (`Dropdown`, `Text`, `Number`, `Checkbox`).
  - Native Share & Export: Uses `csv`, `path_provider`, and `share_plus` to generate and share the `.csv` file via the device's native share sheet.

---

## Directory Structure
```
Pokemon-OCR-FE/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── collection_item.dart
│   │   └── export_field_config.dart
│   ├── screens/
│   │   ├── collection_screen.dart
│   │   ├── scanner_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── csv_export_service.dart
│   ├── utils/
│   │   └── image_cropper.dart
│   └── widgets/
│       ├── card_cutout_overlay.dart
│       └── dynamic_export_dialog.dart
└── pubspec.yaml
```

---

## Setup & Running

### 0. Generate the platform folders (first time only)
This repo only contains `lib/` and `pubspec.yaml`. Create the Android/iOS projects
(existing files in `lib/` are kept):
```bash
flutter create --platforms=android,ios --project-name pokemon_ocr_fe --org com.pokemonocr .
```
Delete the generated `test/widget_test.dart` (it references a `MyApp` class that doesn't exist).
Then add the permissions below.

### 1. Platform Permissions Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)
Add the following permissions inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.FLASHLIGHT" />
```

#### iOS (`ios/Runner/Info.plist`)
Add the following key to `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Scan Pokemon trading cards to identify and add them to your collection.</string>
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Android Emulator (default API connects to http://10.0.2.2:3003)
flutter run

# iOS Simulator or Physical Device (set machine IP in Settings Screen)
flutter run
```
*Note: You can easily configure the backend URL directly inside the app's Settings screen.*

The app has no login screen yet. It identifies itself with `x-user-id: 00000000-0000-0000-0000-000000000001`
(the seeded `demo` user), which the backend only accepts when its `.env` has `DEV_USER_HEADER_AUTH=true`.

