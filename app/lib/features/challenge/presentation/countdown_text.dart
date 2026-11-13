import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../domain/challenge.dart';

/// Live "2d 3h left" countdown to [deadline]. Calls [onExpired] once at zero.
class CountdownText extends ConsumerStatefulWidget {
  const CountdownText({
    super.key,
    required this.deadline,
    this.onExpired,
    this.style,
  });

  final DateTime deadline;
  final VoidCallback? onExpired;
  final TextStyle? style;

  @override
  ConsumerState<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends ConsumerState<CountdownText> {
  Timer? _timer;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final left = widget.deadline.difference(ref.read(clockProvider)());
    if (left <= Duration.zero && !_expiredFired) {
      _expiredFired = true;
      _timer?.cancel();
      widget.onExpired?.call();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final left = widget.deadline.difference(now);
    return Text(
      formatRemaining(left),
      key: const Key('countdown'),
      style: widget.style,
    );
  }
}
