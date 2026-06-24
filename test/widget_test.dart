import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/main.dart';
import 'package:billing_app/core/service_locator.dart' as di;

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize service locator dependencies
    await di.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the widget tree loads successfully
    expect(find.byType(MyApp), findsOneWidget);
  });
}
