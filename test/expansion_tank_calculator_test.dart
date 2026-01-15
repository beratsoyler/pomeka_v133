import 'package:flutter_test/flutter_test.dart';
import 'package:pomeka_v1/services/expansion_tank_calculator.dart';

void main() {
  test('calculates expansion tank volume with Excel v11 inputs', () {
    final calculator = ExpansionTankCalculator();
    final heaterType = ExpansionTankCalculator.heaterTypes.firstWhere(
      (type) => type.labelKey == 'h_floor',
    );

    final result = calculator.calculate(
      capacityKw: 114,
      systemHeightM: 36,
      heaterType: heaterType,
    );

    expect(result.requiredVolume, closeTo(1142.7075, 0.01));
    expect(result.recommendedVolume, 1500);
    expect(result.recommendedVolume >= result.requiredVolume, isTrue);
    expect(
      ExpansionTankCalculator.standardVolumes.contains(
        result.recommendedVolume,
      ),
      isTrue,
    );
  });
}
