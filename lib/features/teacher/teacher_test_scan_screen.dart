import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// Photographed answer sheets — upload, and see where each one landed.
///
/// Reading runs on the server's queue, so a freshly uploaded sheet sits at
/// `reading` until the teacher pulls to refresh; there is no push for this,
/// the same way there is none for AI test generation.
class TeacherTestScanScreen extends StatefulWidget {
  const TeacherTestScanScreen({super.key, required this.testId});

  final String testId;

  @override
  State<TeacherTestScanScreen> createState() => _TeacherTestScanScreenState();
}

class _TeacherTestScanScreenState extends State<TeacherTestScanScreen> {
  final _picker = ImagePicker();
  final _refreshKey = GlobalKey<AsyncViewState<List<PaperScan>>>();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final photos = await _picker.pickMultiImage(imageQuality: 90);
    if (photos.isEmpty || !mounted) return;

    setState(() => _uploading = true);
    try {
      final repo = context.read<TeacherRepository>();
      for (final photo in photos) {
        await repo.uploadScan(widget.testId, photo.path);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
      await _refreshKey.currentState?.refresh();
    }
  }

  Future<void> _assign(PaperScan scan) async {
    final repo = context.read<TeacherRepository>();
    final detail = await repo.test(widget.testId);
    if (!mounted) return;

    final picked = await showModalBottomSheet<TestParticipant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _StudentSheet(students: detail.students),
    );
    if (picked == null || !mounted) return;

    try {
      await repo.assignScan(scan.id, picked.studentTestId);
      if (!mounted) return;
      await _refreshKey.currentState?.refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.scanAnswers),
        actions: [
          IconButton(
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined),
            onPressed: _uploading ? null : _pickAndUpload,
          ),
        ],
      ),
      body: AsyncView<List<PaperScan>>(
        key: _refreshKey,
        load: () => repo.scans(widget.testId),
        builder: (context, scans, refresh) {
          if (scans.isEmpty) {
            return EmptyView(message: s.scanEmpty, icon: Icons.document_scanner_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: scans.length,
            itemBuilder: (context, i) => _ScanRow(
              scan: scans[i],
              onAssign: () => _assign(scans[i]),
              onReview: (studentTestId) =>
                  context.push('/teacher/test/${widget.testId}/student/$studentTestId/review'),
            ),
          );
        },
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({required this.scan, required this.onAssign, required this.onReview});

  final PaperScan scan;
  final VoidCallback onAssign;
  final ValueChanged<String> onReview;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final student = scan.student;

    final (label, background, foreground) = switch (scan.state) {
      'reading' => (s.scanReading, AppColors.sandTint, AppColors.sand),
      'graded' => (s.scanMatched, AppColors.greenTint, AppColors.green),
      'unmatched' => (s.scanUnmatched, AppColors.clayTint, AppColors.clay),
      _ => (s.scanFailed, AppColors.clayTint, AppColors.clay),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: AppShapes.tileRadius,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: student == null ? null : () => onReview(student.studentTestId),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student?.fullName ?? scan.readCode ?? '—',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  if (student?.score != null)
                    Text(
                      '${student!.score}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusChip(label: label, background: background, foreground: foreground),
            if (scan.state == 'unmatched') ...[
              const SizedBox(width: 8),
              GhostButton(label: s.assignToStudent, dense: true, onPressed: onAssign),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentSheet extends StatelessWidget {
  const _StudentSheet({required this.students});

  final List<TestParticipant> students;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            for (final student in students)
              InkWell(
                onTap: () => Navigator.of(context).pop(student),
                borderRadius: AppShapes.tileRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      BlobAvatar(
                        text: student.initials,
                        size: 34,
                        background: AppColors.violetTint,
                        foreground: AppColors.violet,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          student.fullName,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
                        ),
                      ),
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
