import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/core/utils/app_validators.dart';

void main() {
  test('pide nombre y apellido', () {
    expect(AppValidators.fullNameError('Ana'), isNotNull);
    expect(AppValidators.fullNameError('  '), isNotNull);
    expect(AppValidators.fullNameError('A B'), isNotNull);
    expect(AppValidators.fullNameError('Ana Pérez'), isNull);
    expect(AppValidators.fullNameError('  María  José   Solís '), isNull);
  });

  test('sin números y máximo 60 caracteres', () {
    expect(AppValidators.fullNameError('Ana P3rez'), isNotNull);
    expect(AppValidators.fullNameError('Ana ${'x' * 60}'), isNotNull);
  });

  test('normaliza espacios', () {
    expect(AppValidators.normalizeName('  ana   pérez '), 'ana pérez');
  });
}
