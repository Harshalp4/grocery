import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'presentation/providers/refresh.dart';

/// Root widget: wires the router and the light/dark themes, and reacts to the
/// theme toggle via Riverpod.
///
/// Also refreshes catalog data whenever the app returns to the foreground, so
/// changes made in the admin/backend show up without a restart.
class FarmFreshApp extends ConsumerStatefulWidget {
  const FarmFreshApp({super.key});

  @override
  ConsumerState<FarmFreshApp> createState() => _FarmFreshAppState();
}

class _FarmFreshAppState extends ConsumerState<FarmFreshApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshCatalog(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'FarmFresh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
