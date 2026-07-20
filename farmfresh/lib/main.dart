import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/api_config.dart';
import 'data/datasources/api_client.dart';
import 'data/datasources/auth_token.dart';
import 'data/repositories/remote_address_repository.dart';
import 'data/repositories/remote_assistant_repository.dart';
import 'data/repositories/remote_auth_repository.dart';
import 'data/repositories/remote_catalog_repository.dart';
import 'data/repositories/remote_kirana_repository.dart';
import 'data/repositories/remote_order_repository.dart';
import 'presentation/providers/auth_controller.dart';
import 'presentation/providers/repository_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Restore the saved token into the holder before the first API call so the
  // shared ApiClient is authenticated from the start.
  AuthToken.value = prefs.getString('auth_token');

  final overrides = <Override>[
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];

  // When ApiConfig.useRemote is on, back the repositories with the HTTP API.
  // Flip it off (or empty the list) to fall back to the in-memory mocks.
  if (ApiConfig.useRemote) {
    final api = ApiClient();
    overrides.addAll([
      catalogRepositoryProvider
          .overrideWithValue(RemoteCatalogRepository(api)),
      kiranaRepositoryProvider.overrideWithValue(RemoteKiranaRepository(api)),
      assistantRepositoryProvider
          .overrideWithValue(RemoteAssistantRepository(api)),
      orderRepositoryProvider.overrideWithValue(RemoteOrderRepository(api)),
      authRepositoryProvider.overrideWithValue(RemoteAuthRepository(api)),
      addressRepositoryProvider
          .overrideWithValue(RemoteAddressRepository(api)),
    ]);
  }

  // Use an explicit container so a 401 anywhere can cleanly log the user out
  // (clear the invalid token/session) and the UI updates live.
  final container = ProviderContainer(overrides: overrides);
  ApiClient.onUnauthorized = () {
    if (container.read(authControllerProvider).isAuthenticated) {
      container.read(authControllerProvider.notifier).logout();
    }
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FarmFreshApp(),
    ),
  );
}
