import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// A student building their own practice paper.
///
/// Same job as the teacher's create-test screen, much narrower: no groups (it
/// is only ever for me), no variant mode, no advanced flags — a subject, a
/// topic, how many questions. The question pool the server draws from is
/// already weighted toward my own weak skills in that subject; there is
/// nothing left here to configure that on.
class StudentPracticeScreen extends StatelessWidget {
  const StudentPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<StudentRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.practiceTest)),
      body: AsyncView<_Setup>(
        load: () async {
          final loaded = await Future.wait([repo.practiceSubjects(), repo.practiceQuota()]);
          return _Setup(
            subjects: loaded[0] as List<PracticeSubject>,
            quota: loaded[1] as TeacherQuota,
          );
        },
        builder: (context, setup, refresh) => _Form(setup: setup),
      ),
    );
  }
}

class _Setup {
  const _Setup({required this.subjects, required this.quota});

  final List<PracticeSubject> subjects;
  final TeacherQuota quota;
}

class _Form extends StatefulWidget {
  const _Form({required this.setup});

  final _Setup setup;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  PracticeSubject? _subject;
  TeacherProgram? _program;
  bool _loadingProgram = false;
  ProgramBranch? _branch;
  ProgramTopic? _topic;
  int _questionCount = 10;
  TestDifficulty _difficulty = TestDifficulty.mixed;

  bool _busy = false;
  String? _error;
  GenerationJob? _job;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (widget.setup.subjects.length == 1) _selectSubject(widget.setup.subjects.first);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool get _canGenerate =>
      !_busy && _topic != null && !widget.setup.quota.isExhausted;

  Future<void> _selectSubject(PracticeSubject subject) async {
    setState(() {
      _subject = subject;
      _program = null;
      _branch = null;
      _topic = null;
      _loadingProgram = true;
      _error = null;
    });
    try {
      final program = await context.read<StudentRepository>().practiceProgram(subject.id);
      if (!mounted) return;
      setState(() {
        _program = program;
        _loadingProgram = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProgram = false;
        _error = e.message;
      });
    }
  }

  Future<void> _pickTopic() async {
    final program = _program;
    if (program == null) return;
    final picked = await showModalBottomSheet<(ProgramBranch, ProgramTopic)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _TopicSheet(program: program),
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
      final job = await context.read<StudentRepository>().generatePractice(
            topicId: _topic!.id,
            questionCount: _questionCount,
            difficulty: _difficulty,
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

  void _startPolling(String jobId) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final repo = context.read<StudentRepository>();
      try {
        final job = await repo.practiceGenerationState(jobId);
        if (!mounted) return timer.cancel();
        setState(() => _job = job);
        if (job.isDone || job.isFailed) {
          timer.cancel();
          setState(() => _busy = false);
        }
      } on ApiException {
        // The job runs on the server either way; a dropped poll isn't a
        // failed generation.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final job = _job;
    if (job != null) return _Progress(job: job, onRetry: () => setState(() => _job = null));

    final setup = widget.setup;
    if (setup.subjects.isEmpty) {
      return EmptyView(message: s.noProgram, icon: Icons.menu_book_outlined);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _QuotaBanner(quota: setup.quota),
        const SizedBox(height: 14),
        if (setup.subjects.length > 1) ...[
          _Field(
            label: s.pickSubject,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subject in setup.subjects)
                  _Choice(
                    label: subject.name,
                    selected: _subject?.id == subject.id,
                    onTap: () => _selectSubject(subject),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _Field(
          label: s.pickTopic,
          child: _Picker(
            value: _topic == null ? null : '${_branch?.name} · ${_topic!.name}',
            placeholder: s.pickTopic,
            onTap: _loadingProgram || _program == null ? null : _pickTopic,
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          label: s.questionsLabel,
          child: _Stepper(
            value: _questionCount,
            min: 5,
            max: 20,
            step: 5,
            onChanged: (v) => setState(() => _questionCount = v),
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
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            style: const TextStyle(fontSize: 12.5, color: AppColors.clay, height: 1.45),
          ),
        ],
        const SizedBox(height: 22),
        BrandButton(
          label: s.generate,
          busy: _busy,
          onPressed: _canGenerate ? _generate : null,
        ),
      ],
    );
  }
}

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
        color: out ? AppColors.clayTint : AppColors.blueTint,
        borderRadius: AppShapes.tileRadius,
        border: Border.all(color: out ? AppColors.clayLight : AppColors.blueTint),
      ),
      child: Row(
        children: [
          Icon(
            out ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
            size: 18,
            color: out ? AppColors.clay : AppColors.blue,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              out ? s.quotaExhausted : '${s.quotaLeft}: ${quota.remaining} / ${quota.limit}',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: out ? AppColors.clay : AppColors.blueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.job, required this.onRetry});

  final GenerationJob job;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (job.isFailed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyView(message: job.error ?? s.generationFailed, icon: Icons.error_outline_rounded),
            const SizedBox(height: 16),
            BrandButton(label: s.retry, onPressed: onRetry),
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
                colors: [AppColors.blue, AppColors.blueDark],
              ),
              borderRadius: AppShapes.splashOf(110),
              boxShadow: AppShapes.buttonShadow(AppColors.blue),
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
                value: job.progress <= 0 ? null : job.progress,
                minHeight: 8,
                backgroundColor: AppColors.track,
                valueColor: const AlwaysStoppedAnimation(AppColors.blue),
              ),
            )
          else
            BrandButton(
              label: s.start,
              onPressed: () => context.pushReplacement('/student/test/${job.testId}'),
            ),
        ],
      ),
    );
  }
}

/// Branch → topic, in study order — read-only, unlike the teacher's picker:
/// a student practices from the syllabus as it stands, they don't edit it.
class _TopicSheet extends StatelessWidget {
  const _TopicSheet({required this.program});

  final TeacherProgram program;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            Text(program.subjectName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            for (final branch in program.branches) ...[
              if (branch.topics.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
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
                for (final topic in branch.topics)
                  InkWell(
                    onTap: () => Navigator.of(context).pop((branch, topic)),
                    borderRadius: AppShapes.tileRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Text(
                        topic.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
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
  final VoidCallback? onTap;

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

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final int step;
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
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
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
      color: enabled ? AppColors.blueTint : AppColors.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: enabled ? AppColors.blue : AppColors.faint2),
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
      color: selected ? AppColors.blue : AppColors.surface,
      borderRadius: AppShapes.pillRadius,
      child: InkWell(
        borderRadius: AppShapes.pillRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
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
