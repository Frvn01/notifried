import 'package:nowtifried/models/schedule.dart';
import 'package:nowtifried/models/task_item.dart';

/// Realistic CS-student sample data used when storage is empty.
/// All DateTime fields use Nov 3 2026 as the base week-anchor;
/// daysOfWeek drives actual recurrence.

final List<Schedule> sampleSchedules = () {
  // Base date: Monday Nov 2 2026 (weekday 1)
  const base = 2026;

  return [
    Schedule(
      id: 'sample_s1',
      title: 'Software Engineering',
      type: 'school',
      start: DateTime(base, 11, 2, 18, 0),   // 6:00 PM
      end: DateTime(base, 11, 2, 21, 0),     // 9:00 PM
      colorValue: 0xFF5960A0,                // indigo
      daysOfWeek: [1, 3],                    // Mon + Wed
      room: 'GE-301',
    ),
    Schedule(
      id: 'sample_s2',
      title: 'Data Structures',
      type: 'school',
      start: DateTime(base, 11, 4, 7, 30),   // 7:30 AM Tue
      end: DateTime(base, 11, 4, 9, 0),      // 9:00 AM
      colorValue: 0xFF6C5CE7,                // purple
      daysOfWeek: [2, 4],                    // Tue + Thu
      room: 'CS-201',
    ),
    Schedule(
      id: 'sample_s3',
      title: 'Operating Systems',
      type: 'school',
      start: DateTime(base, 11, 2, 15, 0),   // 3:00 PM Mon
      end: DateTime(base, 11, 2, 16, 30),    // 4:30 PM
      colorValue: 0xFF00B894,                // teal
      daysOfWeek: [1, 5],                    // Mon + Fri
      room: 'CS-410',
    ),
    Schedule(
      id: 'sample_s4',
      title: 'Calculus II',
      type: 'school',
      start: DateTime(base, 11, 5, 9, 0),    // 9:00 AM Wed
      end: DateTime(base, 11, 5, 10, 30),    // 10:30 AM
      colorValue: 0xFF0984E3,                // blue
      daysOfWeek: [3, 5],                    // Wed + Fri
      room: 'Math-102',
    ),
    Schedule(
      id: 'sample_s5',
      title: 'Technical Writing',
      type: 'school',
      start: DateTime(base, 11, 4, 13, 0),   // 1:00 PM Tue
      end: DateTime(base, 11, 4, 15, 0),     // 3:00 PM
      colorValue: 0xFFFF9500,                // orange
      daysOfWeek: [2],                       // Tue only
      room: 'Eng-205',
    ),
    Schedule(
      id: 'sample_s6',
      title: 'Computer Networks',
      type: 'school',
      start: DateTime(base, 11, 6, 10, 0),   // 10:00 AM Thu
      end: DateTime(base, 11, 6, 12, 0),     // 12:00 PM
      colorValue: 0xFFE84393,                // pink
      daysOfWeek: [4, 6],                    // Thu + Sat
      room: 'CS-301',
    ),
  ];
}();

List<TaskItem> get sampleTasks {
  final now = DateTime.now();

  // Helper: midnight of now + offset days, at 23:59
  DateTime due(int offsetDays) {
    final d = now.add(Duration(days: offsetDays));
    return DateTime(d.year, d.month, d.day, 23, 59);
  }

  return [
    TaskItem(
      id: 'sample_t1',
      title: 'Software Eng Final Exam',
      type: 'exam',
      dueDate: due(1),
      subject: 'Software Engineering',
      priority: 2,
      colorValue: 0xFF5960A0,
    ),
    TaskItem(
      id: 'sample_t2',
      title: 'Data Structures Quiz 3',
      type: 'quiz',
      dueDate: due(0),
      subject: 'Data Structures',
      priority: 2,
      colorValue: 0xFF6C5CE7,
    ),
    TaskItem(
      id: 'sample_t3',
      title: 'OS Assignment 4',
      type: 'homework',
      dueDate: due(3),
      subject: 'Operating Systems',
      priority: 1,
      colorValue: 0xFF00B894,
    ),
    TaskItem(
      id: 'sample_t4',
      title: 'Calculus Problem Set',
      type: 'homework',
      dueDate: due(5),
      subject: 'Calculus II',
      priority: 1,
      colorValue: 0xFF0984E3,
    ),
    TaskItem(
      id: 'sample_t5',
      title: 'Networks Lab Report',
      type: 'activity',
      dueDate: due(2),
      subject: 'Computer Networks',
      priority: 2,
      colorValue: 0xFFE84393,
    ),
    TaskItem(
      id: 'sample_t6',
      title: 'Tech Writing Draft',
      type: 'activity',
      dueDate: due(7),
      subject: 'Technical Writing',
      priority: 0,
      colorValue: 0xFFFF9500,
    ),
    TaskItem(
      id: 'sample_t7',
      title: 'OS Midterm Exam',
      type: 'exam',
      dueDate: due(14),
      subject: 'Operating Systems',
      priority: 1,
      colorValue: 0xFF00B894,
    ),
    TaskItem(
      id: 'sample_t8',
      title: 'Calculus Quiz',
      type: 'quiz',
      dueDate: due(4),
      subject: 'Calculus II',
      priority: 1,
      colorValue: 0xFF0984E3,
    ),
  ];
}
