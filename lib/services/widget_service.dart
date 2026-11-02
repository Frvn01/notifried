import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/schedule.dart';
import '../models/task_item.dart';
import '../providers/schedule_provider.dart';
import 'storage_service.dart';
import '../widgets/home_widgets_ui.dart';
import '../widgets/schedule/schedule_minimal.dart';
import '../widgets/schedule/schedule_glass.dart';
import '../widgets/schedule/schedule_neon.dart';
import '../widgets/schedule/schedule_timeline.dart';
import '../widgets/schedule/schedule_bento.dart';
import '../widgets/deadlines/deadlines_minimal.dart';
import '../widgets/deadlines/deadlines_glass.dart';
import '../widgets/deadlines/deadlines_neon.dart';
import '../widgets/deadlines/deadlines_timeline.dart';
import '../widgets/deadlines/deadlines_bento.dart';

/// Consolidated data bundle for rendering native Android home screen widgets
class WidgetDataBundle {
  final List<Schedule> schedules;
  final List<TaskItem> tasks;
  final String themeMode; // 'lavender', 'dark', 'light'
  final Color accentColor;
  final String userName;
  final String bgStyle; // 'aurora', 'sunset', 'cyber', 'obsidian', 'lavender', 'emerald'
  final String widgetFamily; // 'schedule', 'deadlines', 'tasks'
  final String widgetVariant; // 'bento', 'glass', 'neon', 'timeline', 'minimal', 'classic'
  final String customTitle; // user-configured header text

  const WidgetDataBundle({
    required this.schedules,
    required this.tasks,
    this.themeMode = 'lavender',
    this.accentColor = const Color(0xFF5960A0),
    this.userName = '',
    this.bgStyle = 'aurora',
    this.widgetFamily = 'schedule',
    this.widgetVariant = 'bento',
    this.customTitle = '',
  });

  Schedule? get nextSchoolClass {
    final now = DateTime.now();
    // 1. Prioritize classes scheduled for today that haven't ended yet
    final todayClasses =
        schedules.where((s) => s.isSchool && s.isToday).toList();
    todayClasses.sort((a, b) => a.todayStart.compareTo(b.todayStart));

    for (final s in todayClasses) {
      if (now.isBefore(s.todayEnd)) return s;
    }

    // 2. Otherwise return the next recurring or upcoming class
    final schoolClasses = schedules.where((s) => s.isSchool).toList();
    if (schoolClasses.isEmpty) return null;
    schoolClasses.sort((a, b) => a.start.compareTo(b.start));
    return schoolClasses.first;
  }

  int get todayClassesCount =>
      schedules.where((s) => s.isSchool && s.isToday).length;

  int get upcomingExamsCount =>
      tasks.where((t) => !t.isDone && t.type.toLowerCase() == 'exam').length;

  int get upcomingQuizzesCount =>
      tasks.where((t) => !t.isDone && t.type.toLowerCase() == 'quiz').length;

  int get pendingTasksCount => tasks
      .where((t) =>
          !t.isDone &&
          t.type.toLowerCase() != 'exam' &&
          t.type.toLowerCase() != 'quiz')
      .length;
}

class WidgetService {
  /// Full-app synchronization: Loads schedules, tasks, theme, and user settings,
  /// then renders Large, Medium, and Small widgets with live frosted glass styling.
  static Future<void> syncAll() async {
    final storage = StorageService();
    final schedules = await storage.loadSchedules();
    final tasks = await storage.loadTasks();
    final themeMode = await storage.loadThemeMode();
    final colVal = await storage.loadThemeColor();
    final userName = await storage.loadUserName();
    final bgStyle = await storage.loadWidgetBgStyle();
    final widgetVariant = await storage.loadWidgetVariant();
    final widgetFamily = await storage.loadWidgetFamily();
    final customTitle = await storage.loadWidgetCustomTitle();

    final bundle = WidgetDataBundle(
      schedules: schedules,
      tasks: tasks,
      themeMode: themeMode,
      accentColor: colVal != null ? Color(colVal) : const Color(0xFF5960A0),
      userName: userName,
      bgStyle: bgStyle,
      widgetVariant: widgetVariant,
      widgetFamily: widgetFamily,
      customTitle: customTitle,
    );

    await _renderAndDispatch(bundle);
  }

  /// Backwards-compatible update method
  static Future<void> updateWidget([List<Schedule>? schedules]) async {
    await syncAll();
  }

  static Widget _buildRenderWidget(
    WidgetDataBundle bundle,
    WidgetSize size,
    Size logicalSize, {
    int? selectedWeekday,
  }) {
    final isDark = bundle.themeMode == 'dark' ||
        bundle.bgStyle == 'obsidian' ||
        bundle.bgStyle == 'cyber';

    if (bundle.widgetVariant == 'classic') {
      switch (size) {
        case WidgetSize.large:
          return ExtraLargeWidgetUI(bundle: bundle);
        case WidgetSize.medium:
          return LargeWidgetUI(bundle: bundle);
        case WidgetSize.small:
          return SmallWidgetUI(bundle: bundle);
      }
    }

    final prov = ScheduleProvider();
    prov.schedules = bundle.schedules.isNotEmpty
        ? bundle.schedules
        : List.from(sampleSchedules);
    prov.tasks = bundle.tasks.isNotEmpty
        ? bundle.tasks
        : List.from(sampleTasks);
    prov.selectedWeekday = selectedWeekday ?? DateTime.now().weekday.clamp(1, 6);

    if (bundle.widgetFamily == 'tasks') {
      prov.setDeadlineFilter('task');
    } else if (bundle.widgetFamily == 'deadlines') {
      prov.setDeadlineFilter('all');
    }

    Widget variantWidget;
    if (bundle.widgetFamily == 'schedule') {
      switch (bundle.widgetVariant) {
        case 'minimal':
          variantWidget = ScheduleMinimal(provider: prov, size: size);
          break;
        case 'glass':
          variantWidget = ScheduleGlass(provider: prov, size: size);
          break;
        case 'neon':
          variantWidget = ScheduleNeon(provider: prov, size: size);
          break;
        case 'timeline':
          variantWidget = ScheduleTimeline(provider: prov, size: size);
          break;
        case 'bento':
        default:
          variantWidget = ScheduleBento(provider: prov, size: size);
          break;
      }
    } else {
      switch (bundle.widgetVariant) {
        case 'minimal':
          variantWidget = DeadlinesMinimal(provider: prov, size: size);
          break;
        case 'glass':
          variantWidget = DeadlinesGlass(provider: prov, size: size);
          break;
        case 'neon':
          variantWidget = DeadlinesNeon(provider: prov, size: size);
          break;
        case 'timeline':
          variantWidget = DeadlinesTimeline(provider: prov, size: size);
          break;
        case 'bento':
        default:
          variantWidget = DeadlinesBento(provider: prov, size: size);
          break;
      }
    }

    return MediaQuery(
      data: MediaQueryData(size: logicalSize),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: bundle.accentColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: bundle.accentColor,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: ChangeNotifierProvider<ScheduleProvider>.value(
            value: prov,
            // TickerMode(enabled: false) disables all AnimationControllers
            // during offscreen bitmap rendering, preventing vsync crashes that
            // cause the red ErrorWidget square in the home-screen widget.
            child: TickerMode(
              enabled: false,
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: logicalSize.width,
                  height: logicalSize.height,
                  child: variantWidget,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _renderAndDispatch(WidgetDataBundle bundle) async {
    final next = bundle.nextSchoolClass;
    final payload = {
      'next_class_title': next?.title ?? 'No classes today',
      'next_class_time': next?.timeRangeFormatted ?? 'All clear',
      'today_classes_count': bundle.todayClassesCount,
      'upcoming_exams_count': bundle.upcomingExamsCount,
      'upcoming_quizzes_count': bundle.upcomingQuizzesCount,
      'pending_tasks_count': bundle.pendingTasksCount,
      'theme_mode': bundle.themeMode,
      'accent_color': bundle.accentColor.toARGB32(),
    };
    final jsonStr = json.encode(payload);

    // 1. Save data to home_widget preferences
    try {
      await HomeWidget.saveWidgetData<String>('schedules_json', jsonStr);
    } catch (_) {}

    // 2. Also save to standard SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('schedules_json', jsonStr);
    } catch (_) {}

    // 3. Render Flutter Widgets to images
    // We render 5 breakpoints per widget family so Android always has the right
    // image regardless of how the user resizes the widget on the home screen.
    //
    // Size key mapping (matching NowtifriedWidgetProvider.kt thresholds):
    //  widget_*_xlarge_image  → 400×380 (large 4×4 grid)
    //  widget_*_large_image   → 400×260 (medium-tall 4×3)
    //  widget_*_medium_image  → 400×170 (2-row bar 4×2)
    //  widget_*_bar_image     → 400×90  (compact 4×1 bar)
    //  widget_*_small_image   → 200×200 (2×2 square)
    try {
      // ── General / Studio-selected adaptive images ─────────────────────────
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(bundle, WidgetSize.large, const Size(400, 380)),
        key: 'widget_extra_large_image',
        logicalSize: const Size(400, 380),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(bundle, WidgetSize.large, const Size(400, 260)),
        key: 'widget_large_image',
        logicalSize: const Size(400, 260),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(bundle, WidgetSize.medium, const Size(400, 170)),
        key: 'widget_medium_image',
        logicalSize: const Size(400, 170),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(bundle, WidgetSize.small, const Size(400, 90)),
        key: 'widget_bar_image',
        logicalSize: const Size(400, 90),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(bundle, WidgetSize.small, const Size(200, 200)),
        key: 'widget_small_image',
        logicalSize: const Size(200, 200),
      );
      // Legacy glance key kept for compatibility
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(bundle, WidgetSize.small, const Size(380, 90)),
        key: 'widget_glance_image',
        logicalSize: const Size(380, 90),
      );

      // Dedicated Schedule Widget images (pre-rendered for all 6 weekdays for in-place home screen interactivity)
      final schedBundle = WidgetDataBundle(
        schedules: bundle.schedules,
        tasks: bundle.tasks,
        themeMode: bundle.themeMode,
        accentColor: bundle.accentColor,
        userName: bundle.userName,
        bgStyle: bundle.bgStyle,
        widgetFamily: 'schedule',
        widgetVariant: bundle.widgetVariant,
        customTitle: bundle.customTitle.isNotEmpty ? bundle.customTitle : 'Schedule',
      );

      final todayWeekday = DateTime.now().weekday.clamp(1, 6);

      // Pre-render day variants 1..6 for both large and xlarge
      for (int day = 1; day <= 6; day++) {
        await HomeWidget.renderFlutterWidget(
          _buildRenderWidget(schedBundle, WidgetSize.large, const Size(400, 380), selectedWeekday: day),
          key: 'widget_schedule_xlarge_day_$day',
          logicalSize: const Size(400, 380),
        );
        await HomeWidget.renderFlutterWidget(
          _buildRenderWidget(schedBundle, WidgetSize.large, const Size(400, 260), selectedWeekday: day),
          key: 'widget_schedule_large_day_$day',
          logicalSize: const Size(400, 260),
        );

        if (bundle.widgetFamily == 'schedule') {
          await HomeWidget.renderFlutterWidget(
            _buildRenderWidget(bundle, WidgetSize.large, const Size(400, 380), selectedWeekday: day),
            key: 'widget_xlarge_day_$day',
            logicalSize: const Size(400, 380),
          );
          await HomeWidget.renderFlutterWidget(
            _buildRenderWidget(bundle, WidgetSize.large, const Size(400, 260), selectedWeekday: day),
            key: 'widget_large_day_$day',
            logicalSize: const Size(400, 260),
          );
        }
      }

      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(schedBundle, WidgetSize.large, const Size(400, 380), selectedWeekday: todayWeekday),
        key: 'widget_schedule_xlarge_image',
        logicalSize: const Size(400, 380),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(schedBundle, WidgetSize.large, const Size(400, 260), selectedWeekday: todayWeekday),
        key: 'widget_schedule_large_image',
        logicalSize: const Size(400, 260),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(schedBundle, WidgetSize.medium, const Size(400, 170), selectedWeekday: todayWeekday),
        key: 'widget_schedule_medium_image',
        logicalSize: const Size(400, 170),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(schedBundle, WidgetSize.small, const Size(400, 90), selectedWeekday: todayWeekday),
        key: 'widget_schedule_bar_image',
        logicalSize: const Size(400, 90),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(schedBundle, WidgetSize.small, const Size(200, 200), selectedWeekday: todayWeekday),
        key: 'widget_schedule_small_image',
        logicalSize: const Size(200, 200),
      );

      // Dedicated Deadlines Widget images (5 breakpoints)
      final deadBundle = WidgetDataBundle(
        schedules: bundle.schedules,
        tasks: bundle.tasks,
        themeMode: bundle.themeMode,
        accentColor: bundle.accentColor,
        userName: bundle.userName,
        bgStyle: bundle.bgStyle,
        widgetFamily: 'deadlines',
        widgetVariant: bundle.widgetVariant,
        customTitle: bundle.customTitle.isNotEmpty ? bundle.customTitle : 'Academic Deadlines',
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(deadBundle, WidgetSize.large, const Size(400, 380)),
        key: 'widget_deadlines_xlarge_image',
        logicalSize: const Size(400, 380),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(deadBundle, WidgetSize.large, const Size(400, 260)),
        key: 'widget_deadlines_large_image',
        logicalSize: const Size(400, 260),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(deadBundle, WidgetSize.medium, const Size(400, 170)),
        key: 'widget_deadlines_medium_image',
        logicalSize: const Size(400, 170),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(deadBundle, WidgetSize.small, const Size(400, 90)),
        key: 'widget_deadlines_bar_image',
        logicalSize: const Size(400, 90),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(deadBundle, WidgetSize.small, const Size(200, 200)),
        key: 'widget_deadlines_small_image',
        logicalSize: const Size(200, 200),
      );

      // Dedicated Tasks Widget images (5 breakpoints)
      final taskBundle = WidgetDataBundle(
        schedules: bundle.schedules,
        tasks: bundle.tasks,
        themeMode: bundle.themeMode,
        accentColor: bundle.accentColor,
        userName: bundle.userName,
        bgStyle: bundle.bgStyle,
        widgetFamily: 'tasks',
        widgetVariant: bundle.widgetVariant,
        customTitle: bundle.customTitle.isNotEmpty ? bundle.customTitle : 'Tasks & Checklist',
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(taskBundle, WidgetSize.large, const Size(400, 380)),
        key: 'widget_tasks_xlarge_image',
        logicalSize: const Size(400, 380),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(taskBundle, WidgetSize.large, const Size(400, 260)),
        key: 'widget_tasks_large_image',
        logicalSize: const Size(400, 260),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(taskBundle, WidgetSize.medium, const Size(400, 170)),
        key: 'widget_tasks_medium_image',
        logicalSize: const Size(400, 170),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(taskBundle, WidgetSize.small, const Size(400, 90)),
        key: 'widget_tasks_bar_image',
        logicalSize: const Size(400, 90),
      );
      await HomeWidget.renderFlutterWidget(
        _buildRenderWidget(taskBundle, WidgetSize.small, const Size(200, 200)),
        key: 'widget_tasks_small_image',
        logicalSize: const Size(200, 200),
      );
    } catch (e, stack) {
      debugPrint('HomeWidget renderFlutterWidget error: $e\n$stack');
    }

    // 4. Trigger native widget update broadcasts
    try {
      // Dedicated Purpose Widgets
      await HomeWidget.updateWidget(
        name: 'ScheduleWidgetProvider',
        androidName: 'ScheduleWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.ScheduleWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'DeadlinesWidgetProvider',
        androidName: 'DeadlinesWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.DeadlinesWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'TasksWidgetProvider',
        androidName: 'TasksWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.TasksWidgetProvider',
      );

      // Adaptive & Backward-compatible widgets
      await HomeWidget.updateWidget(
        name: 'NowtifriedWidgetProvider',
        androidName: 'NowtifriedWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.NowtifriedWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'NowtifriedLargeWidgetProvider',
        androidName: 'NowtifriedLargeWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.NowtifriedLargeWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'NowtifriedMediumWidgetProvider',
        androidName: 'NowtifriedMediumWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.NowtifriedMediumWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'NowtifriedSmallWidgetProvider',
        androidName: 'NowtifriedSmallWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.NowtifriedSmallWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'NowtifriedExtraLargeWidgetProvider',
        androidName: 'NowtifriedExtraLargeWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.NowtifriedExtraLargeWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'NowtifriedGlanceWidgetProvider',
        androidName: 'NowtifriedGlanceWidgetProvider',
        qualifiedAndroidName:
            'com.example.nowtifried.NowtifriedGlanceWidgetProvider',
      );
    } catch (_) {}
  }

  static Future<Map<String, String?>> dumpSharedPrefsCandidates() async {
    final result = <String, String?>{};
    try {
      final val = await HomeWidget.getWidgetData<String>('schedules_json');
      result['HomeWidgetPreferences'] = val;
    } catch (_) {
      result['HomeWidgetPreferences'] = null;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      result['SharedPreferences'] = prefs.getString('schedules_json');
    } catch (_) {
      result['SharedPreferences'] = null;
    }
    return result;
  }
}
