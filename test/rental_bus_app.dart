import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rental_bus_app/main.dart';

void main() {
  testWidgets('Cek Aplikasi Mulai di Halaman Login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(TextField), findsAtLeastNWidgets(1));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
