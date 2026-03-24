/// Centralized validation helpers to avoid duplicating regex patterns.
class AppValidators {
  AppValidators._();

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// Returns `true` when [email] looks like a valid address.
  static bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());
}
