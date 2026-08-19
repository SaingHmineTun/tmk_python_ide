import 'package:flutter_test/flutter_test.dart';
import 'package:tmk_python_ide/app/theme.dart';

void main() {
  test('brand themes use blue and gold', () {
    final light = AppTheme.light().colorScheme;
    final dark = AppTheme.dark().colorScheme;

    expect(light.primary, AppTheme.brandBlue);
    expect(light.secondary, AppTheme.brandGold);
    expect(dark.primary, isNot(AppTheme.brandBlue));
    expect(dark.secondary, isNot(AppTheme.brandGold));
  });
}
