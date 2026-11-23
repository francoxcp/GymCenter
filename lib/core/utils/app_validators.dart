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
