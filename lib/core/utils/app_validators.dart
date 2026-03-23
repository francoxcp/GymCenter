/// Centralized validation helpers to avoid duplicating regex patterns.
class AppValidators {
  AppValidators._();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Returns `true` when [email] looks like a valid address.
  static bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());
}
