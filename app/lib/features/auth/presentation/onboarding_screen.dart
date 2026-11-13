import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../../profile/domain/username.dart';
import 'auth_providers.dart';

/// Pick a username, display name and account privacy; confirm 13+.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  bool _isPrivate = false;
  bool _ageConfirmed = false;
  bool _busy = false;
  String? _usernameError;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefill the display name from Google sign-in, if any.
    final profile = ref.read(myProfileProvider).value;
    _displayName.text = profile?.displayName ?? '';
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _usernameError = null;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    if (!_ageConfirmed) {
      setState(() => _error = 'You must be 13 or older to use Questly.');
      return;
    }
    final userId = ref.read(authStateProvider).value;
    if (userId == null) return;

    setState(() => _busy = true);
    final repo = ref.read(profileRepositoryProvider);
    try {
      if (!await repo.isUsernameAvailable(_username.text)) {
        throw const UsernameTakenException();
      }
      await repo.completeOnboarding(
        userId: userId,
        username: _username.text,
        displayName: _displayName.text,
        isPrivate: _isPrivate,
      );
      ref.invalidate(myProfileProvider);
    } on UsernameTakenException {
      if (mounted) setState(() => _usernameError = 'That username is taken');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('username'),
                      controller: _username,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        helperText: '3–20 characters: a–z, 0–9, _',
                        errorText: _usernameError,
                        border: const OutlineInputBorder(),
                      ),
                      validator: validateUsername,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('display-name'),
                      controller: _displayName,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Display name (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      key: const Key('private'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Private account'),
                      subtitle: const Text(
                        'Your posts default to friends only',
                      ),
                      value: _isPrivate,
                      onChanged: (v) => setState(() => _isPrivate = v),
                    ),
                    CheckboxListTile(
                      key: const Key('age'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('I am 13 or older'),
                      value: _ageConfirmed,
                      onChanged: (v) =>
                          setState(() => _ageConfirmed = v ?? false),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        key: const Key('onboarding-error'),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('finish'),
                      onPressed: _busy ? null : _submit,
                      child: const Text('Start questing'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
