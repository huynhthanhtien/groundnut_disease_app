import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groundnut_disease_app/data/disease_info.dart';
import 'package:groundnut_disease_app/main.dart';
import 'package:groundnut_disease_app/screens/disease_detail_screen.dart';

void main() {
  testWidgets('first launch shows onboarding, then the tab shell', (WidgetTester tester) async {
    // No path_provider in widget tests, so settings start at defaults
    // (onboarding not done) and stay in memory.
    await tester.pumpWidget(const GroundnutDiseaseApp());

    expect(find.text('Nhận diện bệnh cây lạc'), findsOneWidget);
    await tester.tap(find.text('Tôi đã hiểu, bắt đầu'));
    await tester.pump();

    expect(find.text('Quét bệnh'), findsOneWidget);
    expect(find.text('Bệnh hại'), findsOneWidget);
    expect(find.text('Lịch sử'), findsWidgets);

    await tester.tap(find.text('Bệnh hại'));
    await tester.pump();
    expect(find.text('Bệnh hại cây lạc'), findsOneWidget);
    expect(find.text('Bệnh gỉ sắt'), findsOneWidget);
  });

  testWidgets('every disease detail page renders', (WidgetTester tester) async {
    for (final DiseaseInfo info in kDiseases) {
      await tester.pumpWidget(MaterialApp(home: DiseaseDetailScreen(info: info)));
      expect(find.text(info.displayName), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('every model label has disease content', () {
    const labels = [
      'Black Fungus Pod',
      'Early and Late leaf spot',
      'Fungus leaf',
      'Rust-Leaf',
      'black fungus-grondnut',
      'brown Fungus Pod',
    ];
    for (final String l in labels) {
      expect(diseaseInfoFor(l), isNotNull, reason: l);
    }
  });
}
