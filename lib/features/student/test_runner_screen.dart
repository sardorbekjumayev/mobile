import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';
import 'figure_view.dart';
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

  Future<void> _advance() async {
    final s = S.of(context);
    if (!_controller.isLast) {
      _controller.next();
      return;
    }
    final done = await _controller.submit();
    if (!mounted) return;
    if (done) {
      context.pushReplacement('/student/test/${widget.testId}/result');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.error ?? s.somethingWentWrong)),
      );
    }
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
                          for (var i = 0; i < question.options.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _Option(
                                letter: String.fromCharCode(65 + i),
                                text: question.options[i],
                                chosen: controller.chosenIndex == i,
                                onTap: () => controller.choose(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      child: BrandButton(
                        label: controller.phase == RunnerPhase.submitting
                            ? s.submitting
                            : (controller.isLast ? s.finish : s.next),
                        busy: controller.phase == RunnerPhase.submitting,
                        onPressed: controller.chosenIndex == null ? null : _advance,
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
  });

  final String letter;
  final String text;
  final bool chosen;
  final VoidCallback onTap;

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
              if (chosen) Icon(Icons.check_circle_rounded, size: 19, color: brand.primary),
            ],
          ),
        ),
      ),
    );
  }
}
