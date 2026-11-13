import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current time. Overridden in tests so countdowns are deterministic.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
