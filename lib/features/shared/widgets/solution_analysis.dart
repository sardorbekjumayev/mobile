import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/models/solution_models.dart';
import '../../../l10n/strings.dart';
import 'primitives.dart';

/// The state of a worked solution sheet as a coloured chip — `null` is
/// "Yuklanmagan". Used on the teacher roster and at the top of the analysis.
class SolutionStateChip extends StatelessWidget {
  const SolutionStateChip({super.key, required this.state});

  final SolutionState? state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (background, foreground, icon) = switch (state) {
      SolutionState.done => (AppColors.greenTint, AppColors.green, Icons.fact_check_outlined),
      SolutionState.failed => (AppColors.clayTint, AppColors.clay, Icons.error_outline_rounded),
      SolutionState.waiting ||
      SolutionState.analyzing =>
        (AppColors.sandTint, AppColors.sand, Icons.hourglass_top_rounded),
      null => (AppColors.track, AppColors.muted, Icons.upload_file_outlined),
    };
    return StatusChip(
      label: s.solutionStateLabel(state?.name),
      icon: icon,
      background: background,
      foreground: foreground,
    );
  }
}

/// "Yechim tahlili" — the full analysis of a worked solution sheet, identical
/// for the student's result screen and the teacher's review screen.
///
/// While the sheet is on the queue it offers [onRefresh] rather than polling:
/// analysis takes minutes, and a timer hammering the API for that long is the
/// wrong trade. When the sheet is missing or unreadable, [onUpload] (student
/// side only) turns the section into the upload prompt.
class SolutionAnalysisSection extends StatelessWidget {
  const SolutionAnalysisSection({
    super.key,
    required this.solution,
    this.onRefresh,
    this.onUpload,
  });

  final Solution? solution;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sheet = solution;
    final analysis = sheet?.analysis;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(s.solutionAnalysis, trailing: SolutionStateChip(state: sheet?.state)),
          if (sheet != null && sheet.state.isPending) ...[
            const SizedBox(height: 12),
            Text(
              s.solutionRefreshHint,
              style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.muted),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 12),
              GhostButton(label: s.solutionRefresh, onPressed: onRefresh),
            ],
          ],
          if (Solution.needsUpload(sheet)) ...[
            if (sheet?.error != null) ...[
              const SizedBox(height: 12),
              Text(
                sheet!.error!,
                style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.clay),
              ),
            ],
            if (onUpload != null) ...[
              const SizedBox(height: 14),
              SolutionUploadPrompt(retry: sheet != null, onTap: onUpload!),
            ],
          ],
          if (analysis != null) ...[
            const SizedBox(height: 14),
            _AnalysisBody(analysis: analysis),
          ],
        ],
      ),
    );
  }
}

/// The tappable "upload your sheet" card — on the student home (from
/// `pending_solutions`) and inside the result screen's analysis section.
class SolutionUploadPrompt extends StatelessWidget {
  const SolutionUploadPrompt({
    super.key,
    required this.onTap,
    this.retry = false,
    this.title,
  });

  final VoidCallback onTap;
  final bool retry;

  /// The test's title, when the card stands on its own (home screen).
  final String? title;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final foreground = retry ? AppColors.clay : AppColors.sand;

    return Material(
      color: retry ? AppColors.clayTint : AppColors.sandTint,
      borderRadius: AppShapes.tileRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShapes.tileRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              BlobAvatar(
                text: '',
                icon: retry ? Icons.refresh_rounded : Icons.add_a_photo_outlined,
                size: 40,
                background: AppColors.surface,
                foreground: foreground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      retry ? s.solutionPendingRetry : s.solutionPendingTitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    if (title != null && title!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.body),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.analysis});

  final SolutionResult analysis;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final errors = [
      for (final type in SolutionErrorType.all)
        if ((analysis.errorCounts[type] ?? 0) > 0) (type, analysis.errorCounts[type]!),
      // A key a newer backend added still shows up, under its raw name.
      for (final e in analysis.errorCounts.entries)
        if (!SolutionErrorType.all.contains(e.key) &&
            e.key != SolutionErrorType.none &&
            e.value > 0)
          (e.key, e.value),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (analysis.summary.isNotEmpty)
          Text(
            analysis.summary,
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.ink),
          ),
        if (analysis.methodStyle.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Label(s.solutionMethod),
          const SizedBox(height: 4),
          Text(
            analysis.methodStyle,
            style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.body),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (analysis.legibility != null)
              _Metric(
                label: s.solutionLegibility,
                value: '${(analysis.legibility! * 100).round()}%',
                background: AppColors.blueTint2,
                foreground: AppColors.blueDark,
              ),
            _Metric(
              label: s.solutionGuessed,
              value: '${analysis.guessed}',
              background: analysis.guessed > 0 ? AppColors.sandTint : AppColors.surface2,
              foreground: analysis.guessed > 0 ? AppColors.sand : AppColors.muted,
            ),
            _Metric(
              label: s.solutionNoWork,
              value: '${analysis.noWork}',
              background: analysis.noWork > 0 ? AppColors.clayTint : AppColors.surface2,
              foreground: analysis.noWork > 0 ? AppColors.clay : AppColors.muted,
            ),
          ],
        ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Label(s.solutionErrors),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (type, count) in errors)
                StatusChip(
                  label: '${s.solutionErrorType(type)} · $count',
                  background: AppColors.clayTint,
                  foreground: AppColors.clay,
                ),
            ],
          ),
        ],
        _Bullets(
          title: s.solutionStrengths,
          items: analysis.strengths,
          icon: Icons.check_circle_rounded,
          color: AppColors.green,
        ),
        _Bullets(
          title: s.solutionWeaknesses,
          items: analysis.weaknesses,
          icon: Icons.remove_circle_rounded,
          color: AppColors.clay,
        ),
        _Bullets(
          title: s.solutionRecommendations,
          items: analysis.recommendations,
          icon: Icons.lightbulb_rounded,
          color: AppColors.violet,
        ),
        if (analysis.questions.isNotEmpty) ...[
          const SizedBox(height: 18),
          _Label(s.solutionQuestions),
          const SizedBox(height: 8),
          for (final q in analysis.questions) _QuestionRow(question: q),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.faint),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: AppShapes.tileRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: foreground)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: foreground),
          ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(title),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.body),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({required this.question});

  final SolutionQuestion question;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final q = question;
    final clean = q.errorType == SolutionErrorType.none;
    final (avatarBg, avatarFg) = switch (q.isCorrect) {
      true => (AppColors.greenTint, AppColors.green),
      false => (AppColors.clayTint, AppColors.clay),
      null => (AppColors.track, AppColors.muted),
    };
    final (workBg, workFg) = switch (q.work) {
      'full' => (AppColors.greenTint, AppColors.green),
      'partial' => (AppColors.sandTint, AppColors.sand),
      _ => (AppColors.track, AppColors.muted),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppShapes.tileRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlobAvatar(text: '${q.n}', size: 32, background: avatarBg, foreground: avatarFg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusChip(label: s.solutionWork(q.work), background: workBg, foreground: workFg),
                    StatusChip(
                      label: s.solutionErrorType(q.errorType),
                      background: clean ? AppColors.greenTint : AppColors.clayTint,
                      foreground: clean ? AppColors.green : AppColors.clay,
                    ),
                    if (q.guessSuspected)
                      StatusChip(
                        label: s.guessSuspected,
                        icon: Icons.casino_outlined,
                        background: AppColors.sandTint,
                        foreground: AppColors.sand,
                      ),
                  ],
                ),
                if (q.method != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    q.method!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
                if (q.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    q.note!,
                    style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.body),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
