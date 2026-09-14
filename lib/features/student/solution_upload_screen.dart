import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// Opens [SolutionUploadScreen] and resolves `true` once the sheet is on the
/// server — the one entry point the runner, the home cards and the result
/// screen all share.
Future<bool> openSolutionUpload(
  BuildContext context, {
  required String testId,
  required int pages,
  bool retry = false,
  bool submitAfter = false,
}) async {
  final done = await context.push<bool>(Uri(
    path: '/student/test/$testId/solution',
    queryParameters: {
      'pages': '$pages',
      if (retry) 'retry': '1',
      if (submitAfter) 'submit': '1',
    },
  ).toString());
  return done == true;
}

/// "Ishlangan varag'ingizni yuklang" — photographs of the worked solution
/// sheet, sent as one multipart request.
///
/// Pops `true` once the sheet is on the server (including when it already
/// was — `20813`), so the caller can submit the test or refresh its screen.
/// Backing out pops nothing, and the caller treats that as "not yet".
class SolutionUploadScreen extends StatefulWidget {
  const SolutionUploadScreen({
    super.key,
    required this.testId,
    required this.maxPages,
    this.retry = false,
    this.submitAfter = false,
  });

  final String testId;

  /// `solution_pages` — the server refuses more (`20814`).
  final int maxPages;

  /// The last upload was unreadable.
  final bool retry;

  /// Opened from the test runner: the button reads "upload and submit".
  final bool submitAfter;

  @override
  State<SolutionUploadScreen> createState() => _SolutionUploadScreenState();
}

class _SolutionUploadScreenState extends State<SolutionUploadScreen> {
  static const _maxWidth = 2000.0;
  static const _quality = 85;

  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  bool _uploading = false;
  String? _error;

  int get _max => widget.maxPages < 1 ? 1 : widget.maxPages;

  int get _left => _max - _photos.length;

  Future<void> _fromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxWidth,
        imageQuality: _quality,
      );
      if (photo == null || !mounted) return;
      setState(() {
        if (_left > 0) _photos.add(photo);
        _error = null;
      });
    } catch (_) {
      _showPickerError();
    }
  }

  Future<void> _fromGallery() async {
    try {
      final List<XFile> picked;
      // `limit` must be at least 2 — a single free slot takes the one-image
      // picker instead.
      if (_left >= 2) {
        picked = await _picker.pickMultiImage(
          maxWidth: _maxWidth,
          imageQuality: _quality,
          limit: _left,
        );
      } else {
        final one = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: _maxWidth,
          imageQuality: _quality,
        );
        picked = one == null ? const [] : [one];
      }
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _photos.addAll(picked.take(_left));
        _error = null;
      });
    } catch (_) {
      _showPickerError();
    }
  }

  void _showPickerError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(S.of(context).somethingWentWrong)));
  }

  Future<void> _upload() async {
    final s = S.of(context);
    if (_photos.isEmpty) {
      setState(() => _error = s.solutionNeedOne);
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context
          .read<StudentRepository>()
          .uploadSolution(widget.testId, _photos.map((p) => p.path).toList());
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.solutionUploaded)));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Already on file, or not asked for at all: either way there is nothing
      // to upload and the caller should simply carry on.
      if (e.code == ErrorCodes.solutionAlreadyUploaded ||
          e.code == ErrorCodes.solutionNotRequested) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _uploading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return PopScope(
      canPop: !_uploading,
      child: Scaffold(
        appBar: AppBar(title: Text(s.solutionAnalysis)),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Text(s.solutionUploadTitle, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      s.solutionUploadBody,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
                    ),
                    if (widget.retry) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.clayTint,
                          borderRadius: AppShapes.tileRadius,
                          border: Border.all(color: AppColors.clayLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.clay),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.solutionRetryNotice,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: AppColors.clay,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const _Convention(),
                    const SizedBox(height: 18),
                    SectionTitle(
                      s.solutionPagesLabel,
                      trailing: Text(
                        '${_photos.length}/$_max',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _left == 0 ? AppColors.green : AppColors.muted,
                        ),
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
                              onRemove: _uploading
                                  ? null
                                  : () => setState(() => _photos.removeAt(i)),
                            ),
                        ],
                      ),
                    if (_left > 0) ...[
                      if (_photos.isNotEmpty) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PickButton(
                              icon: Icons.photo_camera_outlined,
                              label: s.solutionCamera,
                              primary: true,
                              onTap: _uploading ? null : _fromCamera,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PickButton(
                              icon: Icons.photo_library_outlined,
                              label: s.solutionGallery,
                              onTap: _uploading ? null : _fromGallery,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.clay),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: BrandButton(
                  label: widget.submitAfter ? s.solutionUploadAndSubmit : s.solutionUpload,
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

/// Number in the margin, solve, a horizontal line, next number.
class _Convention extends StatelessWidget {
  const _Convention();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final steps = [s.solutionConvention1, s.solutionConvention2, s.solutionConvention3];

    return AppCard(
      color: AppColors.blueTint2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.solutionConventionTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.blueDark,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlobAvatar(
                    text: '${i + 1}',
                    size: 24,
                    background: AppColors.surface,
                    foreground: AppColors.blueDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        steps[i],
                        style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.body),
                      ),
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
          child: StatusChip(
            label: '$index',
            background: Colors.white.withValues(alpha: 0.9),
            foreground: AppColors.ink,
          ),
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
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? AppColors.blueDark : AppColors.body;
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
        color: primary ? AppColors.blueTint : AppColors.surface,
        borderRadius: AppShapes.tileRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppShapes.tileRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: AppShapes.tileRadius,
              border: Border.all(color: primary ? AppColors.blueLight5 : AppColors.line),
            ),
            child: Column(
              children: [
                Icon(icon, size: 24, color: foreground),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
