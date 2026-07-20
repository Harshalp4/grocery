import '../../domain/entities/basket_line.dart';
import '../../domain/entities/kirana_plan.dart';
import '../../domain/repositories/kirana_repository.dart';
import '../datasources/mock_data.dart';

/// Mock Auto Kirana generator. Today it returns a fixed sensible basket and
/// echoes the household context; the real version calls `POST /kirana/generate`
/// (rule-based, then AI-enhanced).
class MockKiranaRepository implements KiranaRepository {
  const MockKiranaRepository();

  @override
  Future<KiranaPlan> generate(KiranaInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final estimated = MockData.kiranaBasket.fold<int>(
      0,
      (sum, line) => sum + _rupees(line.priceLabel),
    );
    return KiranaPlan(
      title: 'Family of ${input.members} — Monthly Kirana',
      subtitle: '${input.preference} · ${input.usage}',
      lines: MockData.kiranaBasket,
      estimatedTotal: estimated,
    );
  }

  @override
  Future<List<BasketLine>> lastMonthBasket() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockData.repeatBasket;
  }

  int _rupees(String label) {
    final digits = label.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }
}
