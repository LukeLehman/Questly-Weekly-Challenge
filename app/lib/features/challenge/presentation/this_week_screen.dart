import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';

/// Home screen. Phase 1: greets the user and offers sign-out.
/// Phase 2 replaces the body with the weekly challenge card.
class ThisWeekScreen extends ConsumerWidget {
  const ThisWeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('This Week'),
        actions: [
          IconButton(
            key: const Key('sign-out'),
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome, @${profile?.username ?? ''}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Your first quest arrives soon.'),
          ],
        ),
      ),
    );
  }
}
