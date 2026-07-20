import '../../domain/repositories/assistant_repository.dart';
import '../datasources/api_client.dart';

/// AI assistant backed by the HTTP API (`POST /ai/plan`).
class RemoteAssistantRepository implements AssistantRepository {
  RemoteAssistantRepository(this._api);
  final ApiClient _api;

  @override
  Future<String> ask(String prompt) async {
    final j = await _api.postJson('/ai/plan', {'prompt': prompt})
        as Map<String, dynamic>;
    return j['reply'] as String;
  }
}
