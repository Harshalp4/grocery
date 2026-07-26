/// AI Grocery Assistant.
///
/// API mapping: POST /ai/plan {prompt} -> reply text (+ suggested cart later).
abstract interface class AssistantRepository {
  Future<String> ask(String prompt);
}
