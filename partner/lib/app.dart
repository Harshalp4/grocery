import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'data/api_client.dart';
import 'providers.dart';

class PartnerApp extends ConsumerStatefulWidget {
  const PartnerApp({super.key});

  @override
  ConsumerState<PartnerApp> createState() => _PartnerAppState();
}

class _PartnerAppState extends ConsumerState<PartnerApp> {
  final _router = buildRouter();

  @override
  void initState() {
    super.initState();
    // On any 401, drop the session and return to login.
    ApiClient.onUnauthorized = () {
      ref.read(authControllerProvider.notifier).clearSession();
      _router.go('/login');
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FarmFresh Partner',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
