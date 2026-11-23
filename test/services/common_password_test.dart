import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/core/utils/app_validators.dart';

void main() {
  test('rechaza contraseñas comunes aunque cumplan las reglas', () {
    for (final p in [
      'Password1!',
      'Contraseña123!',
      'Qwerty123!',
      'Gimnasio2024!',
      'Gymlab123*',
      'Saprissa10!',
      'Abc12345!',
      'Admin123!',
      '12345678Aa!',
    ]) {
      expect(AppValidators.isCommonPassword(p), isTrue, reason: p);
    }
  });

  test('acepta contraseñas no comunes', () {
    for (final p in ['Tamarindo-Verde7', 'Cafe!Lluvia2031', 'R4yo.Sol_Pasto']) {
      expect(AppValidators.isCommonPassword(p), isFalse, reason: p);
    }
  });

  test('rechaza la que contiene el correo', () {
    expect(
        AppValidators.isCommonPassword('Francisco#99',
            email: 'francisco.mora@gmail.com'),
        isTrue);
    expect(AppValidators.isCommonPassword('Tamarindo-Verde7', email: 'ana@x.com'),
        isFalse);
  });
}
