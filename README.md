# Book Scanner

A Flutter app for Android that lets you organise books into projects, scan pages with your phone camera, and export them as PDF files.

## Features

- **Projects → Books → Pages** hierarchy
- Camera scanning at full sensor resolution
- Photo preview with Retake / Add to Book
- Grid thumbnail view of all scanned pages
- Fullscreen photo viewer with pinch-to-zoom and swipe between pages
- Export any book as a multi-page PDF
- All data stored locally — no internet required

## Project structure

```
lib/
├── main.dart
├── models/
│   ├── project.dart      # Project (contains books)
│   └── book.dart         # Book (contains photo paths)
├── screens/
│   ├── project_list_screen.dart   # Home — list of projects
│   ├── project_detail_screen.dart # Books inside a project
│   ├── book_detail_screen.dart    # Pages (photo grid) + PDF export
│   └── scan_screen.dart           # Camera capture + photo preview
├── services/
│   ├── storage_service.dart  # JSON persistence
│   └── pdf_exporter.dart     # PDF generation from photos
└── utils/
    └── dialogs.dart          # Shared name-input dialog
```

## Getting started

```bash
flutter pub get
flutter run          # connected Android device required
```

**Minimum Android SDK:** 21 (Android 5.0)  
**Target SDK:** 35

## Dependencies

| Package | Purpose |
|---|---|
| `camera` | Camera preview and capture |
| `path_provider` | File system paths |
| `permission_handler` | Runtime camera permission |
| `pdf` | PDF generation |
| `open_filex` | Open exported PDF |
| `intl` | Date formatting |
