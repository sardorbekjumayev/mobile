import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/knowledge_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// "AI xotira" — the teacher's uploads to the platform's memory.
///
/// A test they wrote, or papers their students worked on, photographed. The
/// AI reads the questions and the mistakes; the questions shape only this
/// center's generated tests, the general lessons reach every center.
class TeacherKnowledgeScreen extends StatefulWidget {
  const TeacherKnowledgeScreen({super.key});

  @override
  State<TeacherKnowledgeScreen> createState() => _TeacherKnowledgeScreenState();
}

class _TeacherKnowledgeScreenState extends State<TeacherKnowledgeScreen> {
  final _view = GlobalKey<AsyncViewState<List<KnowledgeSource>>>();
  Timer? _poll;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // While something is being read, check back — the analysis takes a minute
    // or two and nobody should have to pull to find out it finished.
    _poll = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_busy && mounted) _view.currentState?.refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _upload() async {
    final done = await context.push<bool>('/teacher/knowledge-upload');
    if (done == true) await _view.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.knowledgeTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'knowledge-upload',
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
        label: Text(s.knowledgeNew, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: _upload,
      ),
      body: AsyncView<List<KnowledgeSource>>(
        key: _view,
        load: repo.knowledgeSources,
        builder: (context, sources, refresh) {
          _busy = sources.any((x) => x.inProgress);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              Text(
                s.knowledgeBody,
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              const _PrivacyNote(),
              const SizedBox(height: 16),
              if (sources.isEmpty)
                EmptyView(message: s.knowledgeEmpty, icon: Icons.psychology_outlined)
              else
                for (final source in sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SourceCard(
                      source: source,
                      onTap: () async {
                        final changed = await context.push<bool>('/teacher/knowledge/${source.id}');
                        if (changed == true) await refresh();
                      },
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.blueTint2,
      padding: const EdgeInsets.all(14),
      radius: AppShapes.tileRadius,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.blueDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).knowledgePrivacy,
              style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.body),
            ),
          ),
        ],
      ),
    );
  }
}

/// The state as a coloured chip — one place, so the list and the detail agree.
StatusChip knowledgeStateChip(BuildContext context, KnowledgeState state) {
  final s = S.of(context);
  return switch (state) {
    KnowledgeState.queued => StatusChip(
        label: s.knowledgeStateQueued,
        background: AppColors.sandTint,
        foreground: AppColors.sand,
      ),
    KnowledgeState.analyzing => StatusChip(label: s.knowledgeStateAnalyzing),
    KnowledgeState.done => StatusChip(
        label: s.knowledgeStateDone,
        background: AppColors.greenTint,
        foreground: AppColors.green,
      ),
    KnowledgeState.failed => StatusChip(
        label: s.knowledgeStateFailed,
        background: AppColors.clayTint,
        foreground: AppColors.clay,
      ),
  };
}

String _kindLabel(S s, String kind) => switch (kind) {
      'worked' => s.knowledgeKindWorked,
      'material' => s.knowledgeKindMaterial,
      _ => s.knowledgeKindTest,
    };

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.onTap});

  final KnowledgeSource source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final meta = [
      _kindLabel(s, source.kind),
      if (source.subject != null) source.subject!,
      '${source.pages} ${s.knowledgePagesWord}',
      if (source.state == KnowledgeState.done)
        '${source.questions} ${s.knowledgeQuestionsWord} · ${source.lessons} ${s.knowledgeLessonsWord}',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: AppShapes.tileRadius,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  source.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              knowledgeStateChip(context, source.state),
            ],
          ),
          const SizedBox(height: 6),
          Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.faint)),
          if (source.state == KnowledgeState.failed && source.error != null) ...[
            const SizedBox(height: 6),
            Text(source.error!, style: const TextStyle(fontSize: 12, color: AppColors.clay)),
          ],
        ],
      ),
    );
  }
}

// ── upload ─────────────────────────────────────────────────────────────

/// Photographs of a test or of worked papers, a name, and what kind it is.
/// Pops `true` once the upload is on the server.
class KnowledgeUploadScreen extends StatefulWidget {
  const KnowledgeUploadScreen({super.key});

  @override
  State<KnowledgeUploadScreen> createState() => _KnowledgeUploadScreenState();
}

class _KnowledgeUploadScreenState extends State<KnowledgeUploadScreen> {
  static const _max = 30;
  static const _maxWidth = 2000.0;
  static const _quality = 85;

  final _picker = ImagePicker();
  final _title = TextEditingController();
  final List<XFile> _photos = [];
  String _kind = 'test';
  bool _uploading = false;
  String? _error;

  int get _left => _max - _photos.length;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _fromCamera() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: _maxWidth, imageQuality: _quality);
      if (photo == null || !mounted) return;
      setState(() {
        if (_left > 0) _photos.add(photo);
        _error = null;
      });
    } catch (_) {
      _pickerError();
    }
  }

  Future<void> _fromGallery() async {
    try {
      final List<XFile> picked;
      // `limit` must be at least 2 — a single free slot takes the one-image picker.
      if (_left >= 2) {
        picked = await _picker.pickMultiImage(maxWidth: _maxWidth, imageQuality: _quality, limit: _left);
      } else {
        final one = await _picker.pickImage(source: ImageSource.gallery, maxWidth: _maxWidth, imageQuality: _quality);
        picked = one == null ? const [] : [one];
      }
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _photos.addAll(picked.take(_left));
        _error = null;
      });
    } catch (_) {
      _pickerError();
    }
  }

  void _pickerError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).somethingWentWrong)));
  }

  Future<void> _upload() async {
    final s = S.of(context);
    if (_photos.isEmpty) {
      setState(() => _error = s.knowledgeNeedPhoto);
      return;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _error = s.knowledgeNeedName);
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<TeacherRepository>().uploadKnowledge(
            title: _title.text.trim(),
            kind: _kind,
            paths: _photos.map((p) => p.path).toList(),
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.knowledgeUploaded)));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final kinds = {'test': s.knowledgeKindTest, 'worked': s.knowledgeKindWorked, 'material': s.knowledgeKindMaterial};

    return PopScope(
      canPop: !_uploading,
      child: Scaffold(
        appBar: AppBar(title: Text(s.knowledgeNew)),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Text(s.knowledgeTitle, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      s.knowledgeUploadBody,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _title,
                      enabled: !_uploading,
                      maxLength: 160,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: s.knowledgeName, hintText: s.knowledgeNameHint),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in kinds.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: _kind == entry.key,
                            onSelected: _uploading ? null : (_) => setState(() => _kind = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(
                      s.knowledgePages,
                      trailing: Text(
                        '${_photos.length}/$_max',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_photos.isNotEmpty)
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3 / 4,
                        children: [
                          for (var i = 0; i < _photos.length; i++)
                            _Thumb(
                              path: _photos[i].path,
                              index: i + 1,
                              onRemove: _uploading ? null : () => setState(() => _photos.removeAt(i)),
                            ),
                        ],
                      ),
                    if (_left > 0) ...[
                      if (_photos.isNotEmpty) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GhostButton(
                              label: s.solutionCamera,
                              onPressed: _uploading ? null : _fromCamera,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GhostButton(
                              label: s.solutionGallery,
                              onPressed: _uploading ? null : _fromGallery,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    const _PrivacyNote(),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.clay)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: BrandButton(
                  label: s.knowledgeUpload,
                  icon: Icons.cloud_upload_outlined,
                  busy: _uploading,
                  onPressed: _photos.isEmpty || _uploading ? null : _upload,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.index, required this.onRemove});

  final String path;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: AppColors.surface2,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.faint),
            ),
          ),
        ),
        Positioned(
          left: 6,
          bottom: 6,
          child: StatusChip(label: '$index', background: Colors.white.withValues(alpha: 0.9), foreground: AppColors.ink),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(width: 28, height: 28, child: Icon(Icons.close_rounded, size: 16, color: Colors.white)),
              ),
            ),
          ),
      ],
    );
  }
}

// ── detail ─────────────────────────────────────────────────────────────

/// One upload and what it taught. Pops `true` after a delete or retry, so the
/// list refreshes.
class KnowledgeSourceScreen extends StatefulWidget {
  const KnowledgeSourceScreen({super.key, required this.sourceId});

  final String sourceId;

  @override
  State<KnowledgeSourceScreen> createState() => _KnowledgeSourceScreenState();
}

class _KnowledgeSourceScreenState extends State<KnowledgeSourceScreen> {
  bool _changed = false;

  Future<void> _delete() async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.knowledgeDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.knowledgeCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.knowledgeDelete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<TeacherRepository>().deleteKnowledge(widget.sourceId);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.knowledgeTitle),
          actions: [
            IconButton(
              tooltip: s.knowledgeDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
          ],
        ),
        body: AsyncView<KnowledgeSourceDetail>(
          load: () => repo.knowledgeSource(widget.sourceId),
          builder: (context, detail, refresh) {
            final src = detail.source;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(src.title, style: Theme.of(context).textTheme.headlineMedium)),
                    const SizedBox(width: 8),
                    knowledgeStateChip(context, src.state),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [_kindLabel(s, src.kind), if (src.subject != null) src.subject!].join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.faint),
                ),
                if (src.summary != null) ...[
                  const SizedBox(height: 12),
                  Text(src.summary!, style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.body)),
                ],
                if (src.inProgress) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    color: AppColors.blueTint2,
                    padding: const EdgeInsets.all(14),
                    radius: AppShapes.tileRadius,
                    child: Row(
                      children: [
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.knowledgeAnalyzingNote, style: const TextStyle(fontSize: 12.5, color: AppColors.body)),
                        ),
                        GhostButton(label: s.knowledgeRefresh, dense: true, onPressed: refresh),
                      ],
                    ),
                  ),
                ],
                if (src.state == KnowledgeState.failed) ...[
                  const SizedBox(height: 14),
                  if (src.error != null) Text(src.error!, style: const TextStyle(fontSize: 12.5, color: AppColors.clay)),
                  const SizedBox(height: 10),
                  GhostButton(
                    label: s.knowledgeRetry,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await repo.retryKnowledge(src.id);
                        _changed = true;
                        await refresh();
                      } on ApiException catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    },
                  ),
                ],
                if (src.topics.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final t in src.topics) StatusChip(label: t, background: AppColors.tint, foreground: AppColors.body)],
                  ),
                ],
                const SizedBox(height: 16),
                for (final item in detail.items)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: _ItemCard(item: item)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  const _ItemCard({required this.item});

  final KnowledgeItem item;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final item = widget.item;
    final (label, bg, fg) = switch (item.kind) {
      'misconception' => (s.knowledgeKindMisconception, AppColors.clayTint, AppColors.clay),
      'pitfall' => (s.knowledgeKindPitfall, AppColors.sandTint, AppColors.sand),
      'insight' => (s.knowledgeKindInsight, AppColors.greenTint, AppColors.green),
      _ => (s.knowledgeKindExemplar, AppColors.blueTint, AppColors.blueDark),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: AppShapes.tileRadius,
      onTap: item.questionText == null ? null : () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(label: label, background: bg, foreground: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.content, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(
            [
              item.shared ? s.knowledgeShared : s.knowledgePrivate,
              if (item.depth != null) '${s.knowledgeDepth} ${item.depth}/5',
            ].join(' · '),
            style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
          ),
          if (_open && item.questionText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.questionText!, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.body)),
                  for (var i = 0; i < item.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${String.fromCharCode(65 + i)}) ${item.options[i]}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.body),
                      ),
                    ),
                  if (item.answer != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('✓ ${item.answer}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green)),
                    ),
                  if (item.studentError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item.studentError!, style: const TextStyle(fontSize: 12, color: AppColors.clay)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
