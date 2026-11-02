import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nowtifried/data/sample_data.dart';
import 'package:nowtifried/providers/schedule_provider.dart';
import 'package:nowtifried/screens/widget_gallery_screen.dart';
import 'package:nowtifried/widgets/schedule/schedule_minimal.dart';
import 'package:nowtifried/widgets/schedule/schedule_glass.dart';
import 'package:nowtifried/widgets/schedule/schedule_neon.dart';
import 'package:nowtifried/widgets/schedule/schedule_timeline.dart';
import 'package:nowtifried/widgets/schedule/schedule_bento.dart';
import 'package:nowtifried/widgets/deadlines/deadlines_minimal.dart';
import 'package:nowtifried/widgets/deadlines/deadlines_glass.dart';
import 'package:nowtifried/widgets/deadlines/deadlines_neon.dart';
import 'package:nowtifried/widgets/deadlines/deadlines_timeline.dart';
import 'package:nowtifried/widgets/deadlines/deadlines_bento.dart';

void main() {
  late ScheduleProvider provider;

  setUp(() {
    provider = ScheduleProvider();
    provider.schedules = List.from(sampleSchedules);
    provider.tasks = List.from(sampleTasks);
    provider.selectedWeekday = 1; // Monday
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<ScheduleProvider>.value(
          value: provider,
          child: SizedBox(
            width: 400,
            height: 600,
            child: child,
          ),
        ),
      ),
    );
  }

  group("Raven's Agenda - Schedule Family (5 Variants)", () {
    testWidgets('ScheduleMinimal renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ScheduleMinimal(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ScheduleMinimal), findsOneWidget);
    });

    testWidgets('ScheduleGlass renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ScheduleGlass(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ScheduleGlass), findsOneWidget);
    });

    testWidgets('ScheduleNeon renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ScheduleNeon(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ScheduleNeon), findsOneWidget);
    });

    testWidgets('ScheduleTimeline renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ScheduleTimeline(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ScheduleTimeline), findsOneWidget);
    });

    testWidgets('ScheduleBento renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ScheduleBento(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ScheduleBento), findsOneWidget);
    });

    testWidgets('ScheduleBento renders safely inside unconstrained SingleChildScrollView', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<ScheduleProvider>.value(
            value: provider,
            child: SingleChildScrollView(
              child: ScheduleBento(provider: provider, size: WidgetSize.medium),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ScheduleBento), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group("Raven's Agenda - Deadlines Family (5 Variants)", () {
    testWidgets('DeadlinesMinimal renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        DeadlinesMinimal(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DeadlinesMinimal), findsOneWidget);
    });

    testWidgets('DeadlinesGlass renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        DeadlinesGlass(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DeadlinesGlass), findsOneWidget);
    });

    testWidgets('DeadlinesNeon renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        DeadlinesNeon(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DeadlinesNeon), findsOneWidget);
    });

    testWidgets('DeadlinesTimeline renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        DeadlinesTimeline(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DeadlinesTimeline), findsOneWidget);
    });

    testWidgets('DeadlinesBento renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        DeadlinesBento(provider: provider, size: WidgetSize.medium),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DeadlinesBento), findsOneWidget);
    });
  });

  group("Widget Gallery Screen", () {
    testWidgets('WidgetGalleryScreen loads and renders tab bar and action buttons', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: WidgetGalleryScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Widget Gallery'), findsOneWidget);
      expect(find.text('Schedule (5)'), findsOneWidget);
      expect(find.text('Deadlines (5)'), findsOneWidget);
      expect(find.text('Customize Style'), findsOneWidget);
      expect(find.text('Apply Widget'), findsOneWidget);
    });

    testWidgets('WidgetGalleryScreen opens customizer sheet when Customize Style is tapped', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: WidgetGalleryScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final customizeBtn = find.text('Customize Style');
      expect(customizeBtn, findsOneWidget);
      await tester.tap(customizeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Customize Widget'), findsOneWidget);
      expect(find.text('BACKGROUND AESTHETIC STYLE'), findsOneWidget);
      expect(find.text('ACCENT COLOR PALETTE'), findsOneWidget);
      expect(find.text('DATA CONTROLS & TESTING'), findsOneWidget);
    });
  });
}
