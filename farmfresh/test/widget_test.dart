import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farmfresh/app.dart';

void main() {
  testWidgets('App boots to the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FarmFreshApp()));
    await tester.pump();

    // Splash shows the brand name and CTA.
    expect(find.text('FarmFresh'), findsOneWidget);
    expect(find.textContaining('Get Started'), findsOneWidget);
  });
}
