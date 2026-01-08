import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    // There may be ongoing async work (router refresh / prefs load). For a smoke test
    // it's enough to pump a few frames.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Smoke test: app should build.
    expect(find.byType(App), findsOneWidget);
  });
}
