import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aera_demo/src/rust/frb_generated.dart';
import 'package:aera_demo/main.dart';

void main() {
  setUpAll(() async => await RustLib.init());

  testWidgets('switches between pages', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    expect(find.text('Running on'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.piano));
    await tester.pumpAndSettle();
    expect(find.text('Play an arpeggio'), findsOneWidget);
  });
}
