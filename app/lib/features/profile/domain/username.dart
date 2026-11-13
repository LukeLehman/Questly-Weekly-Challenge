/// Mirrors the `username_format` check in the profiles migration.
final _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

String normalizeUsername(String input) => input.trim().toLowerCase();

/// Returns an error message, or null if [input] is a valid username.
String? validateUsername(String? input) {
  final name = normalizeUsername(input ?? '');
  if (name.isEmpty) return 'Pick a username';
  if (name.length < 3) return 'At least 3 characters';
  if (name.length > 20) return 'At most 20 characters';
  if (!_usernamePattern.hasMatch(name)) {
    return 'Letters, numbers and _ only';
  }
  return null;
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}
