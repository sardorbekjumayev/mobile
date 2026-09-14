import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/exam_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';
import 'figure_view.dart';
import 'solution_upload_screen.dart';
import 'test_runner_controller.dart';

/// M8 — the test runner. One question at a time, answers pushed as they are
/// tapped, and a submit that survives a dead connection on the last question.
class TestRunnerScreen extends StatefulWidget {
  const TestRunnerScreen({super.key, required this.testId});

  final String testId;

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  late final TestRunnerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TestRunnerController(
      repository: context.read<StudentRepository>(),
      testId: widget.testId,
    );
    _controller.onTimeUp = _finish;
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmQuit() async {
    final s = S.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.quitTest),
        content: Text(s.quitTestBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.stay)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.quit, style: const TextStyle(color: AppColors.clay)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  /// Next is always available: a student who does not know an answer moves on
  /// and comes back, rather than being held on the question. Finishing with
  /// gaps asks once, so an accidental tap does not hand in a half-done test.
  Future<void> _advance() async {
    final s = S.of(context);
    if (!_controller.isLast) {
      _controller.next();
      return;
    }
    final gaps = _controller.unansweredCount;
    if (gaps > 0) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.unansweredTitle),
          content: Text(s.unansweredBody(gaps)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.keepAnswering)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.finishAnyway)),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    await _finish(s);
  }

  bool _finishing = false;

  /// Finish — from the last question or from the countdown reaching zero.
  ///
  /// A test that requires the worked solution sheet shows the upload step
  /// first; backing out of it leaves the student in the runner, and submit is
  /// never called without the sheet (the server would refuse with `20811`).
  Future<void> _finish([S? strings]) async {
    if (_finishing || !mounted) return;
    _finishing = true;
    try {
      final s = strings ?? S.of(context);
      if (_controller.needsSolution && !await _askForSolution()) return;

      var done = await _controller.submit();
      if (!mounted) return;
      // `20811`: the server wants the sheet after all — show the step once.
      if (!done && _controller.needsSolution) {
        if (!await _askForSolution()) return;
        done = await _controller.submit();
        if (!mounted) return;
      }
      if (done) {
        context.pushReplacement('/student/test/${widget.testId}/result');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_controller.error ?? s.somethingWentWrong)),
        );
      }
    } finally {
      _finishing = false;
    }
  }

  Future<bool> _askForSolution() async {
    final uploaded = await openSolutionUpload(
      context,
      testId: widget.testId,
      pages: _controller.solutionPages,
      submitAfter: true,
    );
    if (uploaded) _controller.markSolutionUploaded();
    return uploaded && mounted;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<TestRunnerController>(
        builder: (context, controller, _) {
          if (controller.phase == RunnerPhase.loading) {
            return const Scaffold(backgroundColor: AppColors.surface, body: LoadingView());
          }
          if (controller.phase == RunnerPhase.failed) {
            return Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(),
              body: ErrorView(
                message: controller.error ?? s.somethingWentWrong,
                retryLabel: s.retry,
                onRetry: controller.start,
              ),
            );
          }

          final question = controller.current;
          if (question == null) {
            return Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(),
              body: EmptyView(message: s.somethingWentWrong),
            );
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _confirmQuit();
            },
            child: Scaffold(
              backgroundColor: AppColors.surface,
              body: SafeArea(
                child: Column(
                  children: [
                    _RunnerBar(controller: controller, onQuit: _confirmQuit),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
                        children: [
                          if (question.skill != null)
                            StatusChip(label: question.skill!),
                          const SizedBox(height: 16),
                          Text(
                            question.text,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 25,
                                  height: 1.25,
                                ),
                          ),
                          const SizedBox(height: 22),
                          if (question.figure != null) FigureView(figure: question.figure!),
                          if (question.mediaUrl != null) _MediaImage(url: question.mediaUrl!),
                          if (question.isMultipleChoice)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                s.multiChoiceHint,
                                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ),
                          if (question.isMultipleChoice)
                            for (var i = 0; i < question.options.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _Option(
                                  letter: String.fromCharCode(65 + i),
                                  text: question.options[i],
                                  chosen: controller.chosenIndexes.contains(i),
                                  multi: true,
                                  onTap: () => controller.toggleMultiple(i),
                                ),
                              )
                          else if (question.isDragAndDrop)
                            _DragAndDropBody(controller: controller, question: question)
                          else
                            for (var i = 0; i < question.options.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _Option(
                                  letter: String.fromCharCode(65 + i),
                                  text: question.options[i],
                                  chosen: controller.chosenIndex == i,
                                  onTap: () => controller.chooseSingle(i),
                                ),
                              ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      child: Row(
                        children: [
                          if (!controller.isFirst) ...[
                            Expanded(
                              child: GhostButton(
                                label: s.previousQuestion,
                                onPressed: controller.phase == RunnerPhase.submitting
                                    ? null
                                    : controller.previous,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 2,
                            child: BrandButton(
                              label: controller.phase == RunnerPhase.submitting
                                  ? s.submitting
                                  : (controller.isLast ? s.finish : s.next),
                              busy: controller.phase == RunnerPhase.submitting,
                              onPressed: _advance,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RunnerBar extends StatelessWidget {
  const _RunnerBar({required this.controller, required this.onQuit});

  final TestRunnerController controller;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final remaining = controller.remaining;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: AppColors.surface,
                shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
                child: InkWell(
                  onTap: onQuit,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.body),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(99)),
                  child: LinearProgressIndicator(
                    value: controller.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.track,
                    valueColor: AlwaysStoppedAnimation(context.brand.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${controller.index + 1}/${controller.total}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          if (remaining != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatDuration(remaining),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: remaining.inMinutes < 2 ? AppColors.clay : AppColors.faint,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `mm:ss`, or `h:mm:ss` past an hour.
String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

class _Option extends StatelessWidget {
  const _Option({
    required this.letter,
    required this.text,
    required this.chosen,
    required this.onTap,
    this.multi = false,
  });

  final String letter;
  final String text;
  final bool chosen;
  final VoidCallback onTap;

  /// `multiple_choice` — a checkmark rather than a filled circle, since more
  /// than one of these can end up chosen at once.
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Material(
      color: chosen ? AppColors.blueTint2 : AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            border: Border.all(
              color: chosen ? brand.primary : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chosen ? brand.primary : AppColors.track,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: chosen ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: chosen ? brand.dark : AppColors.ink,
                  ),
                ),
              ),
              Icon(
                multi
                    ? (chosen ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                    : Icons.check_circle_rounded,
                size: 19,
                color: chosen ? brand.primary : (multi ? AppColors.faint2 : Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The AI-drawn picture. Shown only when one exists; a question the AI could
/// not illustrate simply has no picture slot at all.
class _MediaImage extends StatelessWidget {
  const _MediaImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, _) => frame == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                child: AspectRatio(aspectRatio: 16 / 10, child: child),
              ),
            ),
      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
    );
  }
}

/// `drag_and_drop` — one row per item, a dropdown of target letters. A native
/// drag gesture would read closer to the printed/paper version of this
/// question, but a tap-to-pick dropdown is the more reliable interaction on a
/// small phone screen, and it reuses the same `DropdownButton` the rest of
/// the app already ships.
class _DragAndDropBody extends StatelessWidget {
  const _DragAndDropBody({required this.controller, required this.question});

  final TestRunnerController controller;
  final ExamQuestion question;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final drag = question.dragItems;
    if (drag == null || drag.isEmpty) return const SizedBox.shrink();
    final targets = controller.dragTargets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.dragAndDropHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < drag.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${i + 1}. ${drag.items[i]}',
                      style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: i < targets.length ? targets[i] : null,
                    hint: Text(s.dragAndDropPick, style: const TextStyle(fontSize: 12.5)),
                    underline: const SizedBox.shrink(),
                    items: [
                      for (var t = 0; t < drag.targets.length; t++)
                        DropdownMenuItem(
                          value: t,
                          child: Text(
                            '${String.fromCharCode(65 + t)}) ${drag.targets[t]}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setDragTarget(i, value);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
