import 'package:hive/hive.dart';
import '../models/schedule.dart';
import '../models/task_item.dart';
import '../models/note_item.dart';
import 'widget_service.dart';

class StorageService {
  static const _schedulesBox = 'schedules_box';
  static const _tasksBox = 'tasks_box';
  static const _notesBox = 'notes_box';
  static const _themeBox = 'theme_box';

  // ══════════════════════════════════════════
  // Schedules (Timetable / Classes)
  // ══════════════════════════════════════════

  Future<List<Schedule>> loadSchedules() async {
    if (!Hive.isBoxOpen(_schedulesBox)) return [];
    final box = Hive.box<Schedule>(_schedulesBox);
    return box.values.toList();
  }

  Future<void> saveSchedules(List<Schedule> list) async {
    // update home-screen widget data (best-effort)
    try {
      await WidgetService.updateWidget(list);
    } catch (_) {}
    final box = Hive.box<Schedule>(_schedulesBox);
    await box.clear();
    for (var s in list) {
      await box.add(s);
    }
  }

  Future<void> clearAllSchedules() async {
    final box = Hive.box<Schedule>(_schedulesBox);
    await box.clear();
    try {
      await WidgetService.updateWidget([]);
    } catch (_) {}
  }

  // ══════════════════════════════════════════
  // Tasks (Quizzes, Exams, Activities, etc.)
  // ══════════════════════════════════════════

  Future<List<TaskItem>> loadTasks() async {
    if (!Hive.isBoxOpen(_tasksBox)) return [];
    final box = Hive.box<TaskItem>(_tasksBox);
    return box.values.toList();
  }

  Future<void> saveTasks(List<TaskItem> list) async {
    final box = Hive.box<TaskItem>(_tasksBox);
    await box.clear();
    for (var t in list) {
      await box.add(t);
    }
  }

  Future<void> addTask(TaskItem task) async {
    final box = Hive.box<TaskItem>(_tasksBox);
    await box.add(task);
  }

  Future<void> updateTask(TaskItem task) async {
    final box = Hive.box<TaskItem>(_tasksBox);
    final index = box.values.toList().indexWhere((t) => t.id == task.id);
    if (index != -1) {
      await box.putAt(index, task);
    } else {
      await box.add(task);
    }
  }

  Future<void> deleteTask(String id) async {
    final box = Hive.box<TaskItem>(_tasksBox);
    final index = box.values.toList().indexWhere((t) => t.id == id);
    if (index != -1) {
      await box.deleteAt(index);
    }
  }

  Future<void> clearAllTasks() async {
    final box = Hive.box<TaskItem>(_tasksBox);
    await box.clear();
  }

  // ══════════════════════════════════════════
  // Notes (Reviewers, Guides, Notes)
  // ══════════════════════════════════════════

  Future<List<NoteItem>> loadNotes() async {
    if (!Hive.isBoxOpen(_notesBox)) return [];
    final box = Hive.box<NoteItem>(_notesBox);
    final list = box.values.toList();
    // Sort pinned notes to the top, then newest first
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  Future<void> saveNotes(List<NoteItem> list) async {
    final box = Hive.box<NoteItem>(_notesBox);
    await box.clear();
    for (var n in list) {
      await box.add(n);
    }
  }

  Future<void> addNote(NoteItem note) async {
    final box = Hive.box<NoteItem>(_notesBox);
    await box.add(note);
  }

  Future<void> updateNote(NoteItem note) async {
    final box = Hive.box<NoteItem>(_notesBox);
    final index = box.values.toList().indexWhere((n) => n.id == note.id);
    if (index != -1) {
      await box.putAt(index, note);
    } else {
      await box.add(note);
    }
  }

  Future<void> deleteNote(String id) async {
    final box = Hive.box<NoteItem>(_notesBox);
    final index = box.values.toList().indexWhere((n) => n.id == id);
    if (index != -1) {
      await box.deleteAt(index);
    }
  }

  Future<void> clearAllNotes() async {
    final box = Hive.box<NoteItem>(_notesBox);
    await box.clear();
  }

  // ══════════════════════════════════════════
  // Onboarding Status
  // ══════════════════════════════════════════

  Future<bool> hasSeenOnboarding() async {
    if (!Hive.isBoxOpen(_themeBox)) return false;
    final box = Hive.box(_themeBox);
    return (box.get('has_seen_onboarding_v2') as bool?) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('has_seen_onboarding_v2', true);
  }

  Future<void> resetOnboarding() async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('has_seen_onboarding_v2', false);
  }

  // ══════════════════════════════════════════
  // Theme & User Settings
  // ══════════════════════════════════════════

  Future<int?> loadThemeColor() async {
    if (!Hive.isBoxOpen(_themeBox)) return null;
    final box = Hive.box(_themeBox);
    return box.get('color') as int?;
  }

  Future<void> saveThemeColor(int colorValue) async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('color', colorValue);
  }

  Future<String> loadThemeMode() async {
    if (!Hive.isBoxOpen(_themeBox)) return 'lavender';
    final box = Hive.box(_themeBox);
    return (box.get('theme_mode') as String?) ?? 'lavender';
  }

  Future<void> saveThemeMode(String mode) async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('theme_mode', mode);
  }

  Future<String> loadUserName() async {
    if (!Hive.isBoxOpen(_themeBox)) return '';
    final box = Hive.box(_themeBox);
    return (box.get('user_name') as String?) ?? '';
  }

  Future<void> saveUserName(String name) async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('user_name', name);
  }

  Future<String> loadWidgetBgStyle() async {
    if (!Hive.isBoxOpen(_themeBox)) return 'aurora';
    final box = Hive.box(_themeBox);
    return (box.get('widget_bg_style') as String?) ?? 'aurora';
  }

  Future<void> saveWidgetBgStyle(String style) async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('widget_bg_style', style);
  }

  Future<String> loadWidgetVariant() async {
    if (!Hive.isBoxOpen(_themeBox)) return 'bento';
    final box = Hive.box(_themeBox);
    return (box.get('active_widget_variant') as String?) ?? 'bento';
  }

  Future<void> saveWidgetVariant(String variant) async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('active_widget_variant', variant);
  }

  Future<String> loadWidgetFamily() async {
    if (!Hive.isBoxOpen(_themeBox)) return 'schedule';
    final box = Hive.box(_themeBox);
    return (box.get('active_widget_family') as String?) ?? 'schedule';
  }

  Future<void> saveWidgetFamily(String family) async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('active_widget_family', family);
  }

  Future<String> loadWidgetCustomTitle() async {
    if (!Hive.isBoxOpen(_themeBox)) return '';
    final box = Hive.box(_themeBox);
    return (box.get('widget_custom_title') as String?) ?? '';
  }

  Future<void> saveWidgetCustomTitle(String title) async {
    if (!Hive.isBoxOpen(_themeBox)) return;
    final box = Hive.box(_themeBox);
    await box.put('widget_custom_title', title);
  }
}
