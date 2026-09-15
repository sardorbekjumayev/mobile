import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// "O'z materialimdan" — the phone half of the center panel's material card.
///
/// Photos, a PDF or a DOCX of the teacher's own chapter go up, the server
/// extracts the text, and the AI turns it into up to four topics under the
/// chosen section. Picking one pops `(branch, topic)` back to the create form,
/// whose questions are then built from this very material.
class TeacherMaterialScreen extends StatefulWidget {
  const TeacherMaterialScreen({super.key, required this.program});

  final TeacherProgram program;

  @override
  State<TeacherMaterialScreen> createState() => _TeacherMaterialScreenState();
}

/// A file waiting to go up: its path, and what to call it on the list.
class _Pending {
  const _Pending(this.path, this.name, {this.isImage = false});

  final String path;
  final String name;
  final bool isImage;
}

class _TeacherMaterialScreenState extends State<TeacherMaterialScreen> {
  /// The server's ceiling per upload.
  static const _maxFiles = 6;

  final _picker = ImagePicker();
  final List<_Pending> _files = [];
  List<TeacherMaterial> _materials = [];
  List<ProgramTopic> _topics = [];
  ProgramBranch? _branch;

  bool _uploading = false;
  bool _deriving = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (widget.program.branches.isNotEmpty) _branch = widget.program.branches.first;
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  int get _left => _maxFiles - _files.length;

  bool get _reading => _materials.any((m) => m.isReading);

  Future<void> _fromCamera() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 85);
      if (photo == null || !mounted || _left <= 0) return;
      setState(() => _files.add(_Pending(photo.path, photo.name, isImage: true)));
    } catch (_) {
      _pickerError();
    }
  }

  Future<void> _fromGallery() async {
    try {
      final photos = await _picker.pickMultiImage(maxWidth: 2000, imageQuality: 85);
      if (photos.isEmpty || !mounted) return;
      setState(() => _files.addAll(
            photos.take(_left).map((p) => _Pending(p.path, p.name, isImage: true)),
          ));
    } catch (_) {
      _pickerError();
    }
  }

  Future<void> _fromFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx'],
      );
      if (result == null || !mounted) return;
      setState(() => _files.addAll(
            result.files
                .where((f) => f.path != null)
                .take(_left)
                .map((f) => _Pending(f.path!, f.name)),
          ));
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
    if (_files.isEmpty) {
      setState(() => _error = s.materialNeedFile);
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
      _topics = [];
    });
    try {
      final uploaded = await context.read<TeacherRepository>().uploadMaterial(
            _files.map((f) => f.path).toList(),
          );
      if (!mounted) return;
      setState(() {
        _materials = uploaded;
        _files.clear();
        _uploading = false;
      });
      _startPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = e.message;
      });
    }
  }

  /// Extraction is a queue job — a PDF takes seconds, a photo a little longer.
  void _startPolling() {
    _poll?.cancel();
    var ticks = 0;
    _poll = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || !_reading || ++ticks > 90) return timer.cancel();
      final repo = context.read<TeacherRepository>();
      try {
        final next = await Future.wait(
          _materials.map((m) => m.isReading ? repo.material(m.id) : Future.value(m)),
        );
        if (mounted) setState(() => _materials = next);
      } on ApiException {
        // The job runs either way; the next tick usually lands.
      }
    });
  }

  Future<void> _derive() async {
    final branch = _branch;
    if (branch == null) return;
    setState(() {
      _deriving = true;
      _error = null;
    });
    try {
      final topics = await context.read<TeacherRepository>().topicsFromMaterial(
            branchId: branch.id,
            materialIds: [for (final m in _materials) if (m.isReady) m.id],
          );
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _deriving = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _deriving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final branches = widget.program.branches;

    return PopScope(
      canPop: !_uploading && !_deriving,
      child: Scaffold(
        appBar: AppBar(title: Text(s.materialTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(widget.program.subjectName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                s.fromMaterialHint,
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              _Label(s.materialBranch),
              if (branches.isEmpty)
                EmptyView(message: s.materialNoBranch, icon: Icons.menu_book_outlined)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in branches)
                      ChoiceChip(
                        label: Text(b.name),
                        selected: _branch?.id == b.id,
                        selectedColor: AppColors.violetTint,
                        onSelected: _deriving ? null : (_) => setState(() => _branch = b),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              _Label('${s.materialFiles} · ${_files.length}/$_maxFiles'),
              for (var i = 0; i < _files.length; i++)
                _FileRow(
                  file: _files[i],
                  onRemove: _uploading ? null : () => setState(() => _files.removeAt(i)),
                ),
              if (_left > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: GhostButton(label: s.solutionCamera, onPressed: _uploading ? null : _fromCamera)),
                    const SizedBox(width: 8),
                    Expanded(child: GhostButton(label: s.solutionGallery, onPressed: _uploading ? null : _fromGallery)),
                    const SizedBox(width: 8),
                    Expanded(child: GhostButton(label: s.materialPickFile, onPressed: _uploading ? null : _fromFiles)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(s.materialLimit, style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
              const SizedBox(height: 14),
              BrandButton(
                label: s.materialUpload,
                icon: Icons.cloud_upload_outlined,
                busy: _uploading,
                accent: AppColors.violet,
                onPressed: _files.isEmpty || _uploading || branches.isEmpty ? null : _upload,
              ),
              if (_materials.isNotEmpty) ...[
                const SizedBox(height: 18),
                for (final m in _materials) _MaterialRow(material: m),
                if (_materials.any((m) => m.isReady) && !_reading) ...[
                  const SizedBox(height: 10),
                  BrandButton(
                    label: _deriving ? s.materialDeriving : s.materialDerive,
                    icon: Icons.auto_awesome_rounded,
                    busy: _deriving,
                    accent: AppColors.violet,
                    onPressed: _deriving || _branch == null ? null : _derive,
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.clay)),
              ],
              if (_topics.isNotEmpty && _branch != null) ...[
                const SizedBox(height: 20),
                _Label(s.materialPickTopic),
                for (final t in _topics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      radius: AppShapes.tileRadius,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      onTap: () => Navigator.of(context).pop((_branch!, t)),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 18, color: AppColors.violet),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (t.hint != null && t.hint!.isNotEmpty)
                                  Text(t.hint!, style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
      );
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final _Pending file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: AppShapes.tileRadius,
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: SizedBox(
                width: 40,
                height: 40,
                child: file.isImage
                    ? Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Icon(Icons.image_outlined),
                      )
                    : const ColoredBox(
                        color: AppColors.violetTint,
                        child: Icon(Icons.picture_as_pdf_outlined, color: AppColors.violet),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.faint),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material});

  final TeacherMaterial material;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final m = material;
    final (label, color) = m.isReading
        ? (s.materialReading, AppColors.muted)
        : m.isReady
            ? ('${s.materialReady} · ${m.chars}', AppColors.green)
            : (
                switch (m.error) {
                  '21404' => s.materialNoText,
                  '21405' => s.materialBadPhoto,
                  _ => s.materialFailed,
                },
                AppColors.clay,
              );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(color: AppColors.surface2, borderRadius: AppShapes.tileRadius),
      child: Row(
        children: [
          StatusChip(label: m.kind.toUpperCase(), background: AppColors.violetTint, foreground: AppColors.violet),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: color))),
          if (m.isReading)
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          else if (m.isReady)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.green),
        ],
      ),
    );
  }
}
