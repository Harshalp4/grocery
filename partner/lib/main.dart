import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/push_service.dart';
import 'data/partner_token.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Best-effort FCM init — no-ops without a real Firebase config.
  await PushService.init();
  final prefs = await SharedPreferences.getInstance();
  // Restore the saved token before the first request so the client is authed.
  PartnerToken.value = prefs.getString('partner_token');

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PartnerApp(),
    ),
  );
}
