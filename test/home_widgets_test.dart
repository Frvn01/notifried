import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowtifried/models/schedule.dart';
import 'package:nowtifried/models/task_item.dart';
import 'package:nowtifried/services/widget_service.dart';
import 'package:nowtifried/widgets/glass_container.dart';
import 'package:nowtifried/widgets/home_widgets_ui.dart';

void main() {
  group('Home Screen Widgets UI rendering tests', () {
    final now = DateTime.now();
    final dummySchedule = Schedule(
      id: 'test-1',
      title: 'Operating Systems',
      start: now.add(const Duration(minutes: 45)),
      end: now.add(const Duration(minutes: 135)),
      type: 'school',
      colorValue: 0xFF6C5CE7,
      daysOfWeek: [now.weekday],
    );

    final dummyTask = TaskItem(
      id: 'task-1',
      title: 'Midterm Exam Review',
      type: 'exam',
      dueDate: now.add(const Duration(hours: 3)),
      colorValue: 0xFFFF7675,
      subject: 'CompSci 101',
    );

    final bundle = WidgetDataBundle(
      schedules: [dummySchedule],
      tasks: [dummyTask],
      themeMode: 'lavender',
      accentColor: const Color(0xFF6C5CE7),
      userName: 'Raven',
    );

    testWidgets('LargeWidgetUI renders properly with bundle data', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LargeWidgetUI(bundle: bundle),
        ),
      );
      await tester.pump();

      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.text('Nowtifried'), findsOneWidget);
    });

    testWidgets('MediumWidgetUI renders properly with next class', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediumWidgetUI(bundle: bundle),
        ),
      );
      await tester.pump();

      expect(find.text('Operating Systems'), findsOneWidget);
    });

    testWidgets('SmallWidgetUI renders compact card', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SmallWidgetUI(bundle: bundle),
        ),
      );
      await tester.pump();

      expect(find.text('Operating Systems'), findsOneWidget);
    });

    testWidgets('ExtraLargeWidgetUI renders agenda and room', (tester) async {
      final roomSchedule = Schedule(
        id: 'test-room',
        title: 'Physics Lab',
        start: now.add(const Duration(minutes: 30)),
        end: now.add(const Duration(minutes: 90)),
        type: 'school',
        colorValue: 0xFF00B894,
        room: 'Science Hall 302',
        daysOfWeek: [now.weekday],
      );
      final roomBundle = WidgetDataBundle(
        schedules: [roomSchedule],
        tasks: [dummyTask],
        themeMode: 'lavender',
        accentColor: const Color(0xFF6C5CE7),
        userName: 'Raven',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ExtraLargeWidgetUI(bundle: roomBundle),
        ),
      );
      await tester.pump();

      expect(find.text('Physics Lab'), findsOneWidget);
      expect(find.text('Science Hall 302'), findsOneWidget);
    });

    testWidgets('GlanceWidgetUI renders dynamic island pill', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GlanceWidgetUI(bundle: bundle),
        ),
      );
      await tester.pump();

      expect(find.text('Operating Systems'), findsOneWidget);
    });

    testWidgets('Widgets adapt cleanly to dark theme', (tester) async {
      final darkBundle = WidgetDataBundle(
        schedules: [dummySchedule],
        tasks: [dummyTask],
        themeMode: 'dark',
        accentColor: const Color(0xFF6C5CE7),
        userName: 'Raven',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LargeWidgetUI(bundle: darkBundle),
        ),
      );
      await tester.pump();

      expect(find.text('Operating Systems'), findsOneWidget);
    });

    testWidgets('GlassContainer with onTap triggers bounce animation', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GlassContainer(
            onTap: () => tapped = true,
            child: const Text('Bounce Me'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bounce Me'), findsOneWidget);
      await tester.tap(find.text('Bounce Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
