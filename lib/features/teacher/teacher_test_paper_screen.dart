import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/launcher.dart';
import '../../data/models/exam_models.dart' show DragItems;
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// What was generated, before anyone has taken it.
///
/// The same content [TeacherRepository.testPdf] puts on paper, read here for
/// a quick look right after generation finishes — one common set for a
/// `same`-variant test, or the roster to pick a student's own paper from for
/// a `unique` one.
class TeacherTestPaperScreen extends StatelessWidget {
  const TeacherTestPaperScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.viewVariants)),
      body: AsyncView<TestPaperOverview>(
        load: () => repo.paperOverview(testId),
        builder: (context, overview, refresh) {
          if (overview.isSame && overview.common != null) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(s.commonPaper, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                for (final q in overview.common!) _PaperQuestionCard(question: q),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: overview.students.length,
            itemBuilder: (context, i) {
              final st = overview.students[i];
              return _StudentPaperRow(
                student: st,
                onTap: () => context.push('/teacher/test/$testId/paper/${st.studentTestId}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentPaperRow extends StatelessWidget {
  const _StudentPaperRow({required this.student, required this.onTap});

  final PaperStudentRef student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: AppShapes.tileRadius,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    student.groupName,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

/// One student's own paper — read-only, with the key.
class TeacherStudentPaperScreen extends StatelessWidget {
  const TeacherStudentPaperScreen({
    super.key,
    required this.testId,
    required this.studentTestId,
  });

  final String testId;
  final String studentTestId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.viewVariants)),
      body: AsyncView<StudentPaper>(
        load: () => repo.studentPaper(testId, studentTestId),
        builder: (context, paper, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(paper.fullName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(paper.groupName, style: const TextStyle(fontSize: 12.5, color: AppColors.faint)),
            const SizedBox(height: 16),
            for (final q in paper.questions) _PaperQuestionCard(question: q),
          ],
        ),
      ),
    );
  }
}

class _PaperQuestionCard extends StatelessWidget {
  const _PaperQuestionCard({required this.question});

  final PaperQuestionKey question;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.position}. ${question.text}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            if (question.isImage)
              _MediaPreview(url: question.mediaUrl, icon: Icons.image_outlined)
            else if (question.isAudio)
              _MediaPreview(url: question.mediaUrl, icon: Icons.volume_up_rounded),
            if (question.isDragAndDrop)
              _DragAndDropKey(drag: question.dragItems)
            else
              for (var i = 0; i < question.options.length; i++)
                _KeyOptionRow(
                  letter: letterOf(i),
                  text: question.options[i],
                  isCorrect: question.isMultipleChoice
                      ? (question.answerIndexes?.contains(i) ?? false)
                      : i == question.answerIndex,
                ),
            if ((question.isImage || question.isAudio) && question.mediaUrl == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s.mediaNotAttached,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.clay),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeyOptionRow extends StatelessWidget {
  const _KeyOptionRow({required this.letter, required this.text, required this.isCorrect});

  final String letter;
  final String text;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCorrect ? AppColors.greenTint : AppColors.surface2,
          borderRadius: AppShapes.tileRadius,
        ),
        child: Row(
          children: [
            Text(
              letter,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isCorrect ? AppColors.green : AppColors.body,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 12.5, color: isCorrect ? AppColors.green : AppColors.body),
              ),
            ),
            if (isCorrect) const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.green),
          ],
        ),
      ),
    );
  }
}

/// `image_based`/`audio_based` — a thumbnail, or a play affordance that opens
/// the file externally (the app has no in-app audio player yet).
class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.url, required this.icon});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (url == null) return const SizedBox.shrink();
    final isImage = icon == Icons.image_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: isImage
          ? ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: AppColors.surface2,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, color: AppColors.faint),
                  ),
                ),
              ),
            )
          : Material(
              color: AppColors.blueTint2,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              child: InkWell(
                onTap: () => openExternal(context, url),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.violet),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(S.of(context).playAudio, style: const TextStyle(fontSize: 12.5)),
                      ),
                      const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.faint),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// `drag_and_drop` — the matching key: item, and which target it belongs to.
class _DragAndDropKey extends StatelessWidget {
  const _DragAndDropKey({required this.drag});

  final DragItems? drag;

  @override
  Widget build(BuildContext context) {
    if (drag == null || drag!.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < drag!.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.greenTint, borderRadius: AppShapes.tileRadius),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${i + 1}. ${drag!.items[i]}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.green),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.green),
                  const SizedBox(width: 8),
                  Text(
                    i < drag!.correct.length && drag!.correct[i] < drag!.targets.length
                        ? '${letterOf(drag!.correct[i])}) ${drag!.targets[drag!.correct[i]]}'
                        : '?',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
