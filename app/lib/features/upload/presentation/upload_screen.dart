import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../challenge/domain/challenge.dart';
import '../../challenge/presentation/challenge_providers.dart';
import '../../challenge/presentation/this_week_screen.dart' show categoryIcon;
import '../data/media_picker.dart';
import '../domain/submission.dart';
import 'upload_controller.dart';

/// Post an entry for this week's quest: video, photo, or text.
class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(currentChallengeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Post your entry')),
      body: switch (challenge) {
        AsyncData(value: final c?) => _Gate(challenge: c),
        AsyncData() => const _Message('No quest is open right now.'),
        AsyncError() => const _Message('Couldn\'t load this week\'s quest.'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Only users who accepted and haven't posted yet get the form.
class _Gate extends ConsumerWidget {
  const _Gate({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upload = ref.watch(uploadControllerProvider);
    if (upload is UploadDone) {
      return _Success(challenge: challenge, result: upload);
    }
    final status = ref.watch(myStatusProvider(challenge.id));
    final existing = ref.watch(mySubmissionProvider(challenge.id));
    if (!status.hasValue || !existing.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (existing.value != null) {
      return const _Message('You\'ve already posted your entry this week.');
    }
    if (status.value != ParticipationStatus.accepted) {
      return const _Message('Accept this week\'s quest to post an entry.');
    }
    return _UploadForm(challenge: challenge);
  }
}

class _UploadForm extends ConsumerStatefulWidget {
  const _UploadForm({required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<_UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends ConsumerState<_UploadForm> {
  MediaKind _kind = MediaKind.video;
  XFile? _file;
  Uint8List? _imagePreview;
  final _body = TextEditingController();
  final _caption = TextEditingController();
  late PostVisibility _visibility;

  @override
  void initState() {
    super.initState();
    final isPrivate = ref.read(myProfileProvider).value?.isPrivate ?? false;
    _visibility = isPrivate ? PostVisibility.friends : PostVisibility.public;
  }

  @override
  void dispose() {
    _body.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool camera}) async {
    ref.read(uploadControllerProvider.notifier).reset();
    final file = await ref
        .read(mediaPickerProvider)
        .pick(_kind, camera: camera);
    if (file == null || !mounted) return;
    final preview = _kind == MediaKind.image ? await file.readAsBytes() : null;
    if (!mounted) return;
    setState(() {
      _file = file;
      _imagePreview = preview;
    });
  }

  void _setKind(MediaKind kind) {
    ref.read(uploadControllerProvider.notifier).reset();
    setState(() {
      _kind = kind;
      _file = null;
      _imagePreview = null;
    });
  }

  bool get _ready => switch (_kind) {
    MediaKind.text => _body.text.trim().isNotEmpty,
    _ => _file != null,
  };

  void _submit() {
    ref
        .read(uploadControllerProvider.notifier)
        .submit(
          challenge: widget.challenge,
          kind: _kind,
          file: _file,
          body: _body.text,
          caption: _caption.text,
          visibility: _visibility,
        );
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(uploadControllerProvider);
    final working = upload is UploadWorking;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      categoryIcon(widget.challenge.category),
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.challenge.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<MediaKind>(
                  key: const Key('kind'),
                  segments: const [
                    ButtonSegment(
                      value: MediaKind.video,
                      icon: Icon(Icons.videocam_outlined),
                      label: Text('Video'),
                    ),
                    ButtonSegment(
                      value: MediaKind.image,
                      icon: Icon(Icons.photo_outlined),
                      label: Text('Photo'),
                    ),
                    ButtonSegment(
                      value: MediaKind.text,
                      icon: Icon(Icons.notes),
                      label: Text('Text'),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: working ? null : (s) => _setKind(s.first),
                ),
                const SizedBox(height: 16),
                if (_kind == MediaKind.text)
                  TextField(
                    key: const Key('body'),
                    controller: _body,
                    enabled: !working,
                    minLines: 6,
                    maxLines: 14,
                    maxLength: UploadLimits.maxBody,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Write your poem, story or answer…',
                      border: OutlineInputBorder(),
                    ),
                  )
                else ...[
                  _Preview(kind: _kind, file: _file, image: _imagePreview),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('pick-camera'),
                          onPressed: working ? null : () => _pick(camera: true),
                          icon: Icon(
                            _kind == MediaKind.video
                                ? Icons.videocam
                                : Icons.photo_camera,
                          ),
                          label: Text(
                            _kind == MediaKind.video ? 'Record' : 'Take photo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('pick-gallery'),
                          onPressed: working
                              ? null
                              : () => _pick(camera: false),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose file'),
                        ),
                      ),
                    ],
                  ),
                  if (_kind == MediaKind.video)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        kIsWeb
                            ? 'Up to 60 seconds and 30 MB.'
                            : 'Up to 60 seconds. We\'ll shrink it to 720p.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                TextField(
                  key: const Key('caption'),
                  controller: _caption,
                  enabled: !working,
                  maxLength: UploadLimits.maxCaption,
                  decoration: const InputDecoration(
                    labelText: 'Caption (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Who can see this?', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<PostVisibility>(
                  key: const Key('visibility'),
                  segments: [
                    for (final v in PostVisibility.values)
                      ButtonSegment(value: v, label: Text(v.label)),
                  ],
                  selected: {_visibility},
                  onSelectionChanged: working
                      ? null
                      : (s) => setState(() => _visibility = s.first),
                ),
                const SizedBox(height: 24),
                if (upload case UploadWorking(:final stage, :final progress))
                  Column(
                    key: const Key('progress'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Text(
                        '$stage ${(progress * 100).round()}%',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else ...[
                  if (upload case UploadFailed(:final message))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        message,
                        key: const Key('upload-error'),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  FilledButton.icon(
                    key: const Key('post'),
                    onPressed: _ready ? _submit : null,
                    icon: const Icon(Icons.send),
                    label: Text(
                      upload is UploadFailed ? 'Try again' : 'Post entry',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.kind, required this.file, this.image});

  final MediaKind kind;
  final XFile? file;
  final Uint8List? image;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('preview'),
      height: 220,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: switch ((file, image)) {
        (null, _) => Center(
          child: Icon(
            kind == MediaKind.video ? Icons.videocam_outlined : Icons.photo,
            size: 56,
            color: scheme.outline,
          ),
        ),
        (_, final Uint8List bytes) => Image.memory(bytes, fit: BoxFit.contain),
        (final XFile f, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.movie_outlined, size: 48, color: scheme.primary),
              const SizedBox(height: 8),
              Text(f.name, key: const Key('picked-name')),
            ],
          ),
        ),
      },
    );
  }
}

/// Badge reveal after a successful post.
class _Success extends StatefulWidget {
  const _Success({required this.challenge, required this.result});

  final Challenge challenge;
  final UploadDone result;

  @override
  State<_Success> createState() => _SuccessState();
}

class _SuccessState extends State<_Success>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.result.badgeEarned) ...[
              ScaleTransition(
                scale: CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
                child: Container(
                  key: const Key('badge'),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Icon(
                    categoryIcon(widget.challenge.category),
                    size: 64,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Badge earned!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                widget.challenge.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ] else
              Text('Entry posted!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('done'),
              onPressed: () => context.go('/'),
              child: const Text('Back to This Week'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to This Week'),
            ),
          ],
        ),
      ),
    );
  }
}
