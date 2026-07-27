import '../domain/models.dart';
import 'api_client.dart';

/// All `/partner/*` backend calls.
class PartnerRepository {
  PartnerRepository(this._api);
  final ApiClient _api;

  Future<LoginResult> login(String phone, String password) async {
    final j = await _api.postJson('/partner/auth/login',
        {'phone': phone, 'password': password}) as Map<String, dynamic>;
    return LoginResult(
      token: j['token'] as String,
      partner: Partner.fromJson(j['partner'] as Map<String, dynamic>),
      mustChangePassword: j['mustChangePassword'] as bool? ?? false,
    );
  }

  Future<LoginResult> changePassword(String current, String next) async {
    final j = await _api.postJson('/partner/auth/password',
        {'currentPassword': current, 'newPassword': next}) as Map<String, dynamic>;
    return LoginResult(
      token: j['token'] as String,
      partner: Partner.fromJson(j['partner'] as Map<String, dynamic>),
      mustChangePassword: false,
    );
  }

  Future<bool> setDuty(bool onDuty) async {
    final j = await _api.putJson('/partner/me/duty', {'onDuty': onDuty})
        as Map<String, dynamic>;
    return j['onDuty'] as bool? ?? onDuty;
  }

  Future<List<DeliveryOrder>> orders(String scope) async {
    final data =
        await _api.getJson('/partner/orders', {'scope': scope}) as List<dynamic>;
    return data.map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DeliveryOrder> orderDetail(String id) async =>
      DeliveryOrder.fromJson(await _api.getJson('/partner/orders/$id') as Map<String, dynamic>);

  Future<DeliveryOrder> setStatus(String id, String status) async =>
      DeliveryOrder.fromJson(await _api.postJson('/partner/orders/$id/status',
          {'status': status}) as Map<String, dynamic>);

  Future<DeliveryOrder> deliver(String id,
          {required String otp, required int codCollected, String? note}) async =>
      DeliveryOrder.fromJson(await _api.postJson('/partner/orders/$id/deliver', {
        'otp': otp,
        'codCollected': codCollected,
        if (note != null && note.isNotEmpty) 'note': note,
      }) as Map<String, dynamic>);

  Future<DeliveryOrder> fail(String id, String reason) async =>
      DeliveryOrder.fromJson(await _api.postJson('/partner/orders/$id/fail',
          {'reason': reason}) as Map<String, dynamic>);

  Future<DeliverySummary> summary() async =>
      DeliverySummary.fromJson(await _api.getJson('/partner/summary') as Map<String, dynamic>);

  /// Push a live-location ping so the customer's tracking map can follow us.
  Future<void> sendLocation(double lat, double lng) async {
    try {
      await _api.postJson('/partner/me/location', {'lat': lat, 'lng': lng});
    } catch (_) {/* best effort — don't interrupt the delivery */}
  }

  /// Register this device's FCM token so the backend can push order alerts.
  Future<void> registerDevice(String token, {String platform = 'android'}) async {
    try {
      await _api.postJson('/partner/me/device', {'token': token, 'platform': platform});
    } catch (_) {/* best effort */}
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/partner/auth/logout', const {});
    } catch (_) {/* best effort */}
  }
}
