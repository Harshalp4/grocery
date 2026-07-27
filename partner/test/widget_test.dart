import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:partner/app.dart';
import 'package:partner/providers.dart';

void main() {
  testWidgets('PartnerApp builds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PartnerApp(),
      ),
    );
    expect(find.byType(PartnerApp), findsOneWidget);
  });
}
