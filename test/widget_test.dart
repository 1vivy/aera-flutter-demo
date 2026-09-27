import 'package:flutter_test/flutter_test.dart';

import 'package:aera_app/src/rust/frb_generated.dart';
import 'package:aera_app/main.dart';

void main() {
  setUpAll(() async => await RustLib.init());

  testWidgets('shows where it runs', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.textContaining('Running on'), findsOneWidget);
  });
}
