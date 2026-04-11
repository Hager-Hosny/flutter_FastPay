import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app renders checkout launcher', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('FastPay SDK Example'), findsWidgets);
    expect(find.text('Open FastPay Checkout'), findsOneWidget);
  });
}
