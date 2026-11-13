import 'package:flutter/material.dart';

import '../../../core/env.dart';

/// Phase 0 placeholder. Replaced by the This Week screen in Phase 2.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Questly', style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'A new quest every Monday.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                Env.hasSupabase
                    ? 'Backend configured'
                    : 'Backend not configured',
                key: const Key('backend-status'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
