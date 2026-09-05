import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M20 — a teacher building a test from their phone.
///
/// The center panel's version of this is a four-step wizard across three
/// screens. This is one scrolling form, because the two are not the same job: a
/// center admin sets up a term's worth of tests at a desk, a teacher makes one
/// between lessons and already knows which topic and which group.
///
/// The one thing this screen insists on is the allowance. Generation spends the
/// center's AI budget, so `GET /teacher/quota` is read *before* the form is
/// drawn — being told the limit after filling in six fields is the version of
/// this feature that gets sworn at.
class CreateTestScreen extends StatelessWidget {
  const CreateTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.createTest)),
      body: AsyncView<_Setup>(
        load: () async {
          final loaded = await Future.wait([repo.program(), repo.quota(), repo.groups()]);
          return _Setup(
            program: loaded[0] as TeacherProgram,
            quota: loaded[1] as TeacherQuota,
            groups: loaded[2] as List<TeacherGroup>,
          );
        },
        builder: (context, setup, refresh) => _Form(setup: setup),
      ),
    );
  }
}

class _Setup {
  const _Setup({required this.program, required this.quota, required this.groups});

  final TeacherProgram program;
  final TeacherQuota quota;
  final List<TeacherGroup> groups;
}

class _Form extends StatefulWidget {
  const _Form({required this.setup});

  final _Setup setup;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  ProgramTopic? _topic;
  ProgramBranch? _branch;
  final Set<String> _groupIds = {};
  int _questionCount = 15;
  int _timeLimit = 25;
  TestDifficulty _difficulty = TestDifficulty.mixed;
  TestVariantMode _variantMode = TestVariantMode.same;
  bool _mixPrior = false;

  bool _busy = false;
  String? _error;
  GenerationJob? _job;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // One group is the common case, and pre-selecting it removes a tap from
    // every single use of this screen.
    if (widget.setup.groups.length == 1) _groupIds.add(widget.setup.groups.first.id);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool get _canGenerate =>
      !_busy && _topic != null && _groupIds.isNotEmpty && !widget.setup.quota.isExhausted;

  Future<void> _pickTopic() async {
    final picked = await showModalBottomSheet<(ProgramBranch, ProgramTopic)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _TopicSheet(program: widget.setup.program),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _branch = picked.$1;
      _topic = picked.$2;
      _error = null;
    });
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final job = await context.read<TeacherRepository>().generate(
            topicId: _topic!.id,
            groupIds: _groupIds.toList(),
            questionCount: _questionCount,
            difficulty: _difficulty,
            timeLimitMin: _timeLimit,
            mixPrior: _mixPrior,
            variantMode: _variantMode,
          );
      if (!mounted) return;
      setState(() => _job = job);
      _startPolling(job.jobId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  /// Polls until the job settles.
  ///
  /// Every two seconds rather than every 500ms: generation takes tens of
  /// seconds and the progress the server reports moves in steps, so a faster
  /// poll is four times the requests for the same three numbers.
  void _startPolling(String jobId) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final repo = context.read<TeacherRepository>();
      try {
        final job = await repo.generationState(jobId);
        if (!mounted) return timer.cancel();
        setState(() => _job = job);
        if (job.isDone || job.isFailed) {
          timer.cancel();
          setState(() => _busy = false);
        }
      } on ApiException {
        // A dropped poll is not a failed generation — the job runs on the
        // server either way. Keep polling; the next tick usually lands.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final job = _job;
    if (job != null) return _Progress(job: job, onRetry: () => setState(() => _job = null));

    final setup = widget.setup;
    if (setup.program.isEmpty) {
      return EmptyView(message: s.noProgram, icon: Icons.menu_book_outlined);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _QuotaBanner(quota: setup.quota),
        const SizedBox(height: 14),
        _Field(
          label: s.pickTopic,
          child: _Picker(
            value: _topic == null ? null : '${_branch?.name} · ${_topic!.name}',
            placeholder: s.pickTopic,
            onTap: _pickTopic,
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          label: s.pickGroups,
          child: Column(
            children: [
              for (final group in setup.groups)
                _GroupCheck(
                  group: group,
                  checked: _groupIds.contains(group.id),
                  onChanged: (on) => setState(() {
                    if (on) {
                      _groupIds.add(group.id);
                    } else {
                      _groupIds.remove(group.id);
                    }
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          label: s.questionsLabel,
          child: _Stepper(
            value: _questionCount,
            min: 5,
            max: 40,
            step: 5,
            onChanged: (v) => setState(() => _questionCount = v),
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          label: s.timeLimitLabel,
          child: _Stepper(
            value: _timeLimit,
            min: 5,
            max: 180,
            step: 5,
            suffix: s.minutes,
            onChanged: (v) => setState(() => _timeLimit = v),
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          label: s.difficulty,
          child: Row(
            children: [
              for (final level in TestDifficulty.values) ...[
                Expanded(
                  child: _Choice(
                    label: switch (level) {
                      TestDifficulty.easy => s.difficultyEasy,
                      TestDifficulty.mixed => s.difficultyMixed,
                      TestDifficulty.hard => s.difficultyHard,
                    },
                    selected: _difficulty == level,
                    onTap: () => setState(() => _difficulty = level),
                  ),
                ),
                if (level != TestDifficulty.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          label: s.variantMode,
          child: Row(
            children: [
              for (final mode in TestVariantMode.values) ...[
                Expanded(
                  child: _Choice(
                    label: switch (mode) {
                      TestVariantMode.same => s.variantSame,
                      TestVariantMode.unique => s.variantUnique,
                    },
                    selected: _variantMode == mode,
                    onTap: () => setState(() => _variantMode = mode),
                  ),
                ),
                if (mode != TestVariantMode.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        // A plain Row rather than a SwitchListTile: the tile paints its
        // background and ripple on the nearest Material, and inside AppCard's
        // decorated box that is invisible — Flutter asserts on exactly this.
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.mixPrior,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.mixPriorHint,
                      style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: _mixPrior,
                activeThumbColor: AppColors.violet,
                onChanged: (v) => setState(() => _mixPrior = v),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            key: const Key('create-test-error'),
            style: const TextStyle(fontSize: 12.5, color: AppColors.clay, height: 1.45),
          ),
        ],
        const SizedBox(height: 22),
        BrandButton(
          label: s.generate,
          busy: _busy,
          accent: AppColors.violet,
          onPressed: _canGenerate ? _generate : null,
        ),
      ],
    );
  }
}

/// What is left of the month, and the wall when there is nothing left.
class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.quota});

  final TeacherQuota quota;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final out = quota.isExhausted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: out ? AppColors.clayTint : AppColors.violetTint,
        borderRadius: AppShapes.tileRadius,
        border: Border.all(color: out ? AppColors.clayLight : AppColors.violetTint),
      ),
      child: Row(
        children: [
          Icon(
            out ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
            size: 18,
            color: out ? AppColors.clay : AppColors.violet,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              out ? s.quotaExhausted : '${s.quotaLeft}: ${quota.remaining} / ${quota.limit}',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: out ? AppColors.clay : AppColors.violetDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The screen once the job is queued.
class _Progress extends StatefulWidget {
  const _Progress({required this.job, required this.onRetry});

  final GenerationJob job;
  final VoidCallback onRetry;

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  bool _downloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final bytes = await context.read<TeacherRepository>().testPdf(widget.job.testId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.job.testId}.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final job = widget.job;

    if (job.isFailed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyView(message: job.error ?? s.generationFailed, icon: Icons.error_outline_rounded),
            const SizedBox(height: 16),
            BrandButton(label: s.retry, accent: AppColors.violet, onPressed: widget.onRetry),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.violet, AppColors.violetDark],
              ),
              borderRadius: AppShapes.splashOf(110),
              boxShadow: AppShapes.buttonShadow(AppColors.violet),
            ),
            child: Icon(
              job.isDone ? Icons.check_rounded : Icons.auto_awesome_rounded,
              size: 46,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            job.isDone ? s.testReady : s.generating,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            job.isDone ? (job.title ?? '') : s.generatingHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          if (!job.isDone)
            ClipRRect(
              borderRadius: AppShapes.pillRadius,
              child: LinearProgressIndicator(
                // The server reports real phase progress, so this is a
                // measurement rather than an animation pretending to be one.
                value: job.progress <= 0 ? null : job.progress,
                minHeight: 8,
                backgroundColor: AppColors.track,
                valueColor: const AlwaysStoppedAnimation(AppColors.violet),
              ),
            )
          else ...[
            BrandButton(
              label: s.openTest,
              accent: AppColors.violet,
              onPressed: () => context.pushReplacement('/teacher/test/${job.testId}'),
            ),
            const SizedBox(height: 10),
            Center(
              child: GhostButton(
                label: _downloading ? s.pdfPreparing : s.downloadPdf,
                onPressed: _downloading ? null : _downloadPdf,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Branch → topic, in study order — plus the two writes this sheet owns:
/// adding a section and adding a topic under it, neither of which exists
/// anywhere else in the teacher app.
class _TopicSheet extends StatefulWidget {
  const _TopicSheet({required this.program});

  final TeacherProgram program;

  @override
  State<_TopicSheet> createState() => _TopicSheetState();
}

class _TopicSheetState extends State<_TopicSheet> {
  late List<ProgramBranch> _branches = List.of(widget.program.branches);
  bool _busy = false;

  Future<(String, String?)?> _promptName(String title) {
    final s = S.of(context);
    final nameCtrl = TextEditingController();
    final hintCtrl = TextEditingController();
    return showDialog<(String, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: s.nameFieldLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hintCtrl,
              decoration: InputDecoration(labelText: s.hintFieldLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final hint = hintCtrl.text.trim();
              Navigator.of(context).pop((name, hint.isEmpty ? null : hint));
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  Future<void> _addBranch() async {
    final picked = await _promptName(S.of(context).newBranchTitle);
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final branch = await context
          .read<TeacherRepository>()
          .createBranch(name: picked.$1, hint: picked.$2);
      if (!mounted) return;
      setState(() {
        _branches = [..._branches, branch];
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addTopic(ProgramBranch branch) async {
    final picked = await _promptName(S.of(context).newTopicTitle);
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final topic = await context
          .read<TeacherRepository>()
          .createTopic(branchId: branch.id, name: picked.$1, hint: picked.$2);
      if (!mounted) return;

      // A topic is what makes a section usable, so adding the first one
      // selects it and closes the sheet immediately rather than making the
      // teacher find and tap it a second time.
      final updated = ProgramBranch(
        id: branch.id,
        name: branch.name,
        hint: branch.hint,
        topics: [...branch.topics, topic],
      );
      Navigator.of(context).pop((updated, topic));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.program.subjectName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _addBranch,
                  child: Text(s.addBranch),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final branch in _branches) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        branch.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: AppColors.faint,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _busy ? null : () => _addTopic(branch),
                      borderRadius: AppShapes.tileRadius,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Text(
                          s.addTopic,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.violet,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final topic in branch.topics)
                InkWell(
                  onTap: () => Navigator.of(context).pop((branch, topic)),
                  borderRadius: AppShapes.tileRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (topic.isCustom)
                          const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.violet),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({required this.value, required this.placeholder, required this.onTap});

  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = value != null;
    return AppCard(
      radius: AppShapes.tileRadius,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? placeholder,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
                color: chosen ? AppColors.ink : AppColors.faint2,
              ),
            ),
          ),
          const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.faint),
        ],
      ),
    );
  }
}

class _GroupCheck extends StatelessWidget {
  const _GroupCheck({required this.group, required this.checked, required this.onChanged});

  final TeacherGroup group;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: AppShapes.tileRadius,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => onChanged(!checked),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: checked ? AppColors.violet : AppColors.faint2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${group.studentsCount} ${s.studentsLower}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.suffix,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppShapes.tileRadius,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          _Round(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged((value - step).clamp(min, max)),
          ),
          Expanded(
            child: Text(
              suffix == null ? '$value' : '$value $suffix',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          _Round(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.violetTint : AppColors.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: enabled ? AppColors.violet : AppColors.faint2),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.violet : AppColors.surface,
      borderRadius: AppShapes.pillRadius,
      child: InkWell(
        borderRadius: AppShapes.pillRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
