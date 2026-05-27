class Validators {
  Validators._();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? name(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter your name';
    if (s.length < 2) return 'Name must be at least 2 characters';
    if (s.length > 50) return 'Name must be 50 characters or fewer';
    return null;
  }

  static String? emailOptional(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_emailRegex.hasMatch(s)) return 'Please enter a valid email';
    return null;
  }
}
