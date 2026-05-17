/// Centralized validation helpers to avoid duplicating regex patterns.
class AppValidators {
  AppValidators._();

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
