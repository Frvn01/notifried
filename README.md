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

Widget setup (Android scaffolded)
- I added a basic Android widget layout and provider under `android/app/src/main/` (`res/layout/widget_nowtifried.xml`, `res/xml/nowtifried_widget_info.xml`, and `kotlin/com/example/nowtifried/NowtifriedWidgetProvider.kt`).
- To fully enable the widget: merge the files into your app, ensure the package path matches your app package, rebuild the Android app, then add the widget from the launcher. For a dynamic widget tied to app data, follow the `home_widget` package docs and adapt `NowtifriedWidgetProvider` to read the `schedules_json` value saved by the plugin.
 - To fully enable the widget: merge the files into your app, ensure the package path matches your app package, rebuild the Android app, then add the widget from the launcher. The scaffolded `NowtifriedWidgetProvider` attempts to read `schedules_json` from SharedPreferences and shows the next 3 upcoming schedules.
 - If you use the `home_widget` plugin (Dart) to save `schedules_json`, the provider will pick it up; if your project uses a different SharedPreferences name, update `NowtifriedWidgetProvider.readSchedulesJson` to match the actual preferences name used on your device.

Storage (Hive)
- The app now uses `hive` and `hive_flutter` for local storage; no external backend required. Hive stores data inside the app's sandbox.

Permissions
- The app requests Android `POST_NOTIFICATIONS` at runtime; if denied, an in-app dialog will let the user retry or open app settings.
