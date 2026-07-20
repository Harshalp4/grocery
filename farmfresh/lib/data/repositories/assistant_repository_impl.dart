import '../../domain/repositories/assistant_repository.dart';

/// Canned AI Assistant replies (mirrors the wireframe's dummy response).
/// Replace with a `POST /ai/plan` call to the Claude-backed backend later.
class MockAssistantRepository implements AssistantRepository {
  const MockAssistantRepository();

  @override
  Future<String> ask(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return "Here's a suggested basket 👇\n\n"
        'Suggested cart\n'
        'Rice 10kg · Atta 15kg · Toor Dal 3kg · Oil 5L · Tea 1kg\n\n'
        'Est. monthly qty: ~34 kg / 5 L\n'
        'Health tip: add millets twice a week for fibre 🌱\n'
        'Est. total: ₹4,250* (placeholder)';
  }
}
