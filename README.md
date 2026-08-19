# Nowtifried

Simple Flutter schedule system with local notifications and theme color customization.

Features
- Add schedules (school/work/reminder) with start/end times and color.
- Local notifications scheduled at the start time. Android notifications are set ongoing so they persist until cleared by the app.
- Theme color can be customized.

Run

1. Ensure Flutter SDK is installed.
2. From project folder run:

```bash
flutter pub get
flutter run
```

Android notes
- Add the notification permission and initialization in `AndroidManifest.xml` if targeting Android 13+.
- Ongoing notifications are Android-specific; on iOS the system handles notification dismissal differently.

Home-screen widget
- Adding a native home-screen widget requires platform integration. Consider using the `home_widget` package and follow its README to add widgets for Android and iOS.
