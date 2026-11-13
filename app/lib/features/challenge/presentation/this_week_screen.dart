import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge.dart';
import 'challenge_providers.dart';
import 'countdown_text.dart';

/// Home: this week's quest card, countdown, and accept/decline.
class ThisWeekScreen extends ConsumerWidget {
  const ThisWeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final challenge = ref.watch(currentChallengeProvider);

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
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(currentChallengeProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile?.username != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Hi @${profile!.username}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    switch (challenge) {
                      AsyncData(value: final c?) => _QuestCard(challenge: c),
                      AsyncData() => const _NoQuest(),
                      AsyncError() => _LoadError(
                        onRetry: () => ref.invalidate(currentChallengeProvider),
                      ),
                      _ => const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accepted = ref.watch(acceptedCountProvider(challenge.id)).value ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: scheme.primaryContainer,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          avatar: Icon(categoryIcon(challenge.category)),
                          label: Text(categoryLabel(challenge.category)),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: scheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        CountdownText(
                          deadline: challenge.closesAt,
                          onExpired: () =>
                              ref.invalidate(currentChallengeProvider),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      challenge.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (challenge.tips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Tips', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      for (final tip in challenge.tips)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ),
                    ],
                    if (accepted > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        accepted == 1
                            ? '1 quester has accepted'
                            : '$accepted questers have accepted',
                        key: const Key('accepted-count'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResponsePanel(challenge: challenge),
      ],
    );
  }
}

/// Accept / decline buttons, or the user's current answer.
class _ResponsePanel extends ConsumerStatefulWidget {
  const _ResponsePanel({required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<_ResponsePanel> createState() => _ResponsePanelState();
}

class _ResponsePanelState extends ConsumerState<_ResponsePanel> {
  bool _busy = false;

  Future<void> _respond(ParticipationStatus status) async {
    final userId = ref.read(authStateProvider).value;
    if (userId == null) return;
    final id = widget.challenge.id;
    setState(() => _busy = true);
    try {
      await ref
          .read(challengeRepositoryProvider)
          .respond(challengeId: id, userId: userId, status: status);
      ref
        ..invalidate(myStatusProvider(id))
        ..invalidate(acceptedCountProvider(id));
    } on ChallengeClosedException {
      _snack('This quest has closed.');
      ref.invalidate(currentChallengeProvider);
    } catch (_) {
      _snack('Couldn\'t save your answer. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(myStatusProvider(widget.challenge.id));
    final theme = Theme.of(context);

    if (!status.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (status.value) {
      null => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('decline'),
              onPressed: _busy
                  ? null
                  : () => _respond(ParticipationStatus.declined),
              child: const Text('Not this week'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              key: const Key('accept'),
              onPressed: _busy
                  ? null
                  : () => _respond(ParticipationStatus.accepted),
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Accept quest'),
            ),
          ),
        ],
      ),
      ParticipationStatus.accepted => _StatusBanner(
        key: const Key('status-accepted'),
        icon: Icons.check_circle,
        color: theme.colorScheme.primary,
        message: 'You\'re in! Post your entry before the timer runs out.',
        action: TextButton(
          key: const Key('change-to-decline'),
          onPressed: _busy
              ? null
              : () => _respond(ParticipationStatus.declined),
          child: const Text('Change my mind'),
        ),
      ),
      ParticipationStatus.declined => _StatusBanner(
        key: const Key('status-declined'),
        icon: Icons.do_not_disturb_on_outlined,
        color: theme.colorScheme.outline,
        message: 'You\'re sitting this one out.',
        action: FilledButton(
          key: const Key('accept'),
          onPressed: _busy
              ? null
              : () => _respond(ParticipationStatus.accepted),
          child: const Text('Accept after all'),
        ),
      ),
    };
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final Color color;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            action,
          ],
        ),
      ),
    );
  }
}

class _NoQuest extends StatelessWidget {
  const _NoQuest();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, size: 48),
          SizedBox(height: 12),
          Text('No quest right now', key: Key('no-quest')),
          SizedBox(height: 4),
          Text('A new quest drops every Monday.'),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          const Text('Couldn\'t load this week\'s quest'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

IconData categoryIcon(String category) => switch (category) {
  'baking' => Icons.cake_outlined,
  'poetry' => Icons.format_quote,
  'drawing' => Icons.brush_outlined,
  'music' => Icons.music_note_outlined,
  'fitness' => Icons.fitness_center,
  'photography' => Icons.photo_camera_outlined,
  'magic' => Icons.auto_awesome,
  'origami' => Icons.change_history,
  'cooking' => Icons.restaurant_outlined,
  'language' => Icons.translate,
  'dance' => Icons.directions_run,
  'writing' => Icons.edit_note,
  _ => Icons.flag_outlined,
};

String categoryLabel(String category) =>
    category.isEmpty ? '' : category[0].toUpperCase() + category.substring(1);
