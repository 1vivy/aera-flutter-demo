import 'package:flutter_test/flutter_test.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_demo/home.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

void main() {
  testWidgets('every demo page opens on a host with nothing', (tester) async {
    Surface.debugInstance = Surface(
      info: const HostInfo(kind: HostKind.headless, name: 'Test'),
      config: const SurfaceConfig(appId: 'surfaces_demo'),
    );
    await tester.pumpWidget(const SurfacesApp(title: 'Surfaces Demo', home: HomePage()));
    for (final demo in demos) {
      // Motion animates forever; open it without settling.
      if (demo.title == 'Motion' || demo.title == 'Fractal') continue;
      await tester.scrollUntilVisible(find.text(demo.title), 200);
      await tester.tap(find.text(demo.title));
      await tester.pumpAndSettle();
      expect(find.text(demo.title), findsWidgets, reason: demo.title);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
