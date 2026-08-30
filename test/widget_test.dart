import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:free_map_review/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FreeMapReviewApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
