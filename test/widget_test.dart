import 'package:flutter_test/flutter_test.dart';
import 'package:nowtifried/main.dart';

void main() {
  testWidgets('renders the Nowtifried app', (WidgetTester tester) async {
    await tester.pumpWidget(const NowtifriedApp());
    await tester.pump();
    expect(find.text('Nowtifried'), findsWidgets);
  });
}
