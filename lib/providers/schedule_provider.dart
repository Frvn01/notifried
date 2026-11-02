import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../models/task_item.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';

class ScheduleProvider extends ChangeNotifier {
  List<Schedule> schedules = [];
  List<TaskItem> tasks = [];

  // Weekday 1=Mon..6=Sat, clamped so Sunday maps to Monday
  int selectedWeekday = () {
    final d = DateTime.now().weekday; // 1=Mon..7=Sun
    return d.clamp(1, 6);
  }();

  String deadlineFilter = 'all';

  // ── Data loading ────────────────────────────────────────────────────

  Future<void> loadData() async {
    final svc = StorageService();
    schedules = await svc.loadSchedules();
    tasks = await svc.loadTasks();
    notifyListeners();
  }

  /// Seeds sample data if the current lists are empty (e.g. for preview galleries).
  void seedIfEmpty({List<Schedule>? sampleSchedules, List<TaskItem>? sampleTasks}) {
    bool changed = false;
    if (schedules.isEmpty && sampleSchedules != null && sampleSchedules.isNotEmpty) {
      schedules = List.from(sampleSchedules);
      changed = true;
    }
    if (tasks.isEmpty && sampleTasks != null && sampleTasks.isNotEmpty) {
      tasks = List.from(sampleTasks);
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  // ── Selection / filter setters ───────────────────────────────────────

  void selectWeekday(int d) {
    selectedWeekday = d.clamp(1, 6);
    notifyListeners();
  }

  void setDeadlineFilter(String f) {
    deadlineFilter = f;
    notifyListeners();
  }

  /// Flips isDone on the task with [id], persists, and notifies.
  Future<void> toggleTaskDone(String id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    tasks[idx].isDone = !tasks[idx].isDone;
    await StorageService().updateTask(tasks[idx]);
    notifyListeners();
    try {
      await WidgetService.syncAll();
    } catch (_) {}
  }

  void addTask(TaskItem item) {
    tasks.add(item);
    notifyListeners();
  }

  // ── Computed getters ─────────────────────────────────────────────────

  /// All school schedules that fall on [weekday].
  List<Schedule> schedulesForDay(int weekday) {
    return schedules.where((s) {
      if (!s.isSchool) return false;
      if (s.daysOfWeek != null && s.daysOfWeek!.isNotEmpty) {
        return s.daysOfWeek!.contains(weekday);
      }
      return s.start.weekday == weekday;
    }).toList()
      ..sort((a, b) => a.start.hour != b.start.hour
          ? a.start.hour.compareTo(b.start.hour)
          : a.start.minute.compareTo(b.start.minute));
  }

  /// First incomplete class today, or first class of the next school day.
  Schedule? get nextClass {
    final todayWd = DateTime.now().weekday.clamp(1, 6);
    final todayClasses = schedulesForDay(todayWd);

    // Find first class that is not yet completed today
    final upcoming = todayClasses.where((s) => !s.isPastDue).toList();
    if (upcoming.isNotEmpty) return upcoming.first;

    // Look forward up to 6 days for the next school day with classes
    for (int delta = 1; delta <= 6; delta++) {
      final wd = ((todayWd - 1 + delta) % 6) + 1; // cycles 1..6
      final next = schedulesForDay(wd);
      if (next.isNotEmpty) return next.first;
    }
    return null;
  }

  /// Active (not done) tasks filtered by [deadlineFilter], sorted by dueDate.
  List<TaskItem> get filteredDeadlines {
    return tasks.where((t) {
      if (t.isDone) return false;
      if (deadlineFilter == 'all') return true;
      if (deadlineFilter == 'exam') return t.type == 'exam';
      if (deadlineFilter == 'quiz') return t.type == 'quiz';
      if (deadlineFilter == 'task') {
        return t.type != 'exam' && t.type != 'quiz';
      }
      return true;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Urgency color for a task: red → amber → neutral.
  Color urgencyColor(TaskItem t) {
    if (t.isDueToday || t.isDueTomorrow || t.isOverdue) {
      return const Color(0xFFFF3B30); // red
    }
    final daysLeft = t.dueDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 3) {
      return const Color(0xFFFF9500); // amber
    }
    return AppColors.textMuted; // neutral grey-purple
  }
}
