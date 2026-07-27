import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/push_service.dart';
import 'data/api_client.dart';
import 'data/partner_repository.dart';
import 'data/partner_token.dart';
import 'domain/models.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('overridden in main()'),
);

final partnerRepositoryProvider =
    Provider<PartnerRepository>((ref) => PartnerRepository(ApiClient()));

class AuthState {
  const AuthState({this.partner});
  final Partner? partner;
  bool get isAuthed => partner != null;
}

/// Holds the signed-in partner + persists the session.
class AuthController extends Notifier<AuthState> {
  static const _kToken = 'partner_token';
  static const _kPartner = 'partner_profile';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AuthState build() {
    final pj = _prefs.getString(_kPartner);
    if (PartnerToken.value != null && pj != null) {
      return AuthState(
          partner: Partner.fromJson(jsonDecode(pj) as Map<String, dynamic>));
    }
    return const AuthState();
  }

  /// Returns true when the partner must change their password first.
  Future<bool> login(String phone, String password) async {
    final r = await ref.read(partnerRepositoryProvider).login(phone, password);
    await _persist(r);
    return r.mustChangePassword;
  }

  Future<void> changePassword(String current, String next) async {
    final r = await ref
        .read(partnerRepositoryProvider)
        .changePassword(current, next);
    await _persist(r);
  }

  Future<void> setDuty(bool onDuty) async {
    final v = await ref.read(partnerRepositoryProvider).setDuty(onDuty);
    final p = state.partner;
    if (p != null) {
      final next = p.copyWith(onDuty: v);
      await _prefs.setString(_kPartner, jsonEncode(_toJson(next)));
      state = AuthState(partner: next);
    }
  }

  Future<void> logout() async {
    await ref.read(partnerRepositoryProvider).logout();
    clearSession();
  }

  /// Drop the local session without a network call (used on a 401).
  void clearSession() {
    PartnerToken.value = null;
    _prefs.remove(_kToken);
    _prefs.remove(_kPartner);
    state = const AuthState();
  }

  Future<void> _persist(LoginResult r) async {
    PartnerToken.value = r.token;
    await _prefs.setString(_kToken, r.token);
    await _prefs.setString(_kPartner, jsonEncode(_toJson(r.partner)));
    state = AuthState(partner: r.partner);
    // Register this device for push now that we're authed (no-op if push off).
    unawaited(_registerPush());
  }

  Future<void> _registerPush() async {
    final token = await PushService.deviceToken();
    if (token == null) return;
    await ref.read(partnerRepositoryProvider).registerDevice(token);
  }

  Map<String, dynamic> _toJson(Partner p) => {
        'id': p.id,
        'name': p.name,
        'phone': p.phone,
        'active': p.active,
        'onDuty': p.onDuty,
        'mustChangePassword': p.mustChangePassword,
        'vehicleType': p.vehicleType,
        'vehicleNumber': p.vehicleNumber,
        'zone': p.zone,
      };
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

final ordersProvider = FutureProvider.family<List<DeliveryOrder>, String>(
  (ref, scope) => ref.watch(partnerRepositoryProvider).orders(scope),
);

final orderDetailProvider = FutureProvider.family<DeliveryOrder, String>(
  (ref, id) => ref.watch(partnerRepositoryProvider).orderDetail(id),
);

final summaryProvider = FutureProvider<DeliverySummary>(
  (ref) => ref.watch(partnerRepositoryProvider).summary(),
);
