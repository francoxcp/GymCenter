import 'package:flutter/services.dart';

/// Formatter that limits name fields to max 40 non-digit characters
/// and max 10 digits (0-9) simultaneously.
class NameInputFormatter extends TextInputFormatter {
  final int maxLetters;
  final int maxDigits;

  const NameInputFormatter({this.maxLetters = 40, this.maxDigits = 10});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    final letters = text.replaceAll(RegExp(r'[0-9]'), '').length;
    if (digits > maxDigits || letters > maxLetters) return oldValue;
    return newValue;
  }
}

/// Centralized validation helpers to avoid duplicating regex patterns.
class AppValidators {
  AppValidators._();

  // Palabras base de las contraseñas más usadas y filtradas (también en
  // Costa Rica). Se comparan solo las letras: "Saprissa10!" → "saprissa".
  static const _commonWords = {
    'password', 'passw', 'pass', 'contrasena', 'clave', 'qwerty', 'qwertz',
    'asdf', 'asdfgh', 'zxcvbn', 'admin', 'administrador', 'root', 'user',
    'usuario', 'test', 'prueba', 'abc', 'abcd', 'abcde', 'abcdef', 'letmein',
    'welcome', 'bienvenido', 'hola', 'iloveyou', 'teamo', 'amor', 'love',
    'dragon', 'monkey', 'master', 'gymlab', 'gimnasio', 'gym', 'fitness',
    'saprissa', 'liga', 'herediano', 'futbol', 'costarica', 'puravida',
  };

  /// ¿Es una contraseña común o fácil de adivinar? Revisa palabras muy
  /// usadas, secuencias (1234, 1111) y partes del correo de la persona.
  static bool isCommonPassword(String password, {String? email}) {
    String norm(String v) => v
        .toLowerCase()
        .replaceAll(RegExp('[áä]'), 'a')
        .replaceAll(RegExp('[éë]'), 'e')
        .replaceAll(RegExp('[íï]'), 'i')
        .replaceAll(RegExp('[óö]'), 'o')
        .replaceAll(RegExp('[úü]'), 'u')
        .replaceAll('ñ', 'n');
    final p = norm(password);
    final letters = p.replaceAll(RegExp('[^a-z]'), '');
    final digits = p.replaceAll(RegExp('[^0-9]'), '');
    if (_commonWords.contains(letters)) return true;
    // Casi solo números: "12345678Aa!", "1111aa!"
    if (letters.length <= 2 && _isSequence(digits)) return true;
    if (email != null) {
      final local = norm(email.split('@').first);
      for (final part in local.split(RegExp('[^a-z0-9]'))) {
        if (part.length >= 4 && p.contains(part)) return true;
      }
    }
    return false;
  }

  static bool _isSequence(String d) {
    if (d.length < 4) return false;
    var up = true, down = true, same = true;
    for (var i = 1; i < d.length; i++) {
      final diff = d.codeUnitAt(i) - d.codeUnitAt(i - 1);
      up &= diff == 1;
      down &= diff == -1;
      same &= diff == 0;
    }
    return up || down || same;
  }

  static const commonPasswordMessage =
      'Esa contraseña es muy común o fácil de adivinar. Usa otra.';

  /// Quita espacios de más: "  ana   pérez " → "ana pérez".
  static String normalizeName(String v) =>
      v.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// El nombre no se puede cambiar después: exige nombre y apellido.
  /// Devuelve el mensaje de error, o null si es válido.
  static String? fullNameError(String? value) {
    final v = normalizeName(value ?? '');
    final parts = v.split(' ').where((p) => p.length >= 2).toList();
    if (parts.length < 2) return 'Escribe nombre y apellido.';
    if (RegExp(r'[0-9]').hasMatch(v)) return 'El nombre no lleva números.';
    if (v.length > 60) return 'Máximo 60 caracteres.';
    return null;
  }

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// Returns `true` when [email] looks like a valid address.
  static bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  /// Sanitizes free-text input: strips HTML tags and control characters,
  /// trims whitespace, and limits to [maxLength] characters.
  static String sanitize(String input, {int maxLength = 500}) {
    var s = input
        .replaceAll(RegExp(r'<[^>]*>'), '') // strip HTML tags
        .replaceAll(
            RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '') // control chars
        .trim();
    if (s.length > maxLength) s = s.substring(0, maxLength);
    return s;
  }

  /// Returns `true` if [input] contains patterns indicative of XSS or SQL injection.
  static bool hasInjectionRisk(String input) {
    return RegExp(
      r"<script|<iframe|javascript:|on\w+\s*=|'--|;\s*drop\s|;\s*select\s|;\s*insert\s|;\s*update\s|;\s*delete\s",
      caseSensitive: false,
    ).hasMatch(input);
  }
}
