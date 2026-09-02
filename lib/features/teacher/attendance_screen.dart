import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M16 — `POST /teacher/attendance`, the one write a teacher makes.
///
/// The endpoint upserts on `(group_id, student_id, lesson_date)`, so saving the
/// register twice corrects it rather than failing — which is exactly what a
/// teacher who mis-tapped is about to do.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, AttendanceStatus> _marks = {};
  DateTime _date = DateTime.now();
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(List<RosterEntry> roster) async {
    final s = S.of(context);
    setState(() => _saving = true);
    try {
      await context.read<TeacherRepository>().markAttendance(
            groupId: widget.groupId,
            lessonDate: _date,
            // A student left untouched is present: the common case is a full
            // room with two absences, and making the teacher tap forty times
            // to say so is how a register stops being filled in.
            records: [
              for (final entry in roster)
                AttendanceMark(
                  studentId: entry.id,
                  status: _marks[entry.id] ?? AttendanceStatus.present,
                ),
            ],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.registerSaved)));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.register)),
      body: AsyncView<TeacherGroupDetail>(
        load: () => repo.group(widget.groupId),
        builder: (context, detail, refresh) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  AppCard(
                    radius: AppShapes.tileRadius,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 18, color: AppColors.faint),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, d MMMM').format(_date),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.faint2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in detail.roster)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AttendanceRow(
                        entry: entry,
                        status: _marks[entry.id] ?? AttendanceStatus.present,
                        onChanged: (status) => setState(() => _marks[entry.id] = status),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: BrandButton(
                label: s.saveRegister,
                busy: _saving,
                onPressed: detail.roster.isEmpty ? null : () => _save(detail.roster),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.entry,
    required this.status,
    required this.onChanged,
  });

  final RosterEntry entry;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = {
      AttendanceStatus.present: s.present,
      AttendanceStatus.late: s.late,
      AttendanceStatus.absent: s.absent,
      AttendanceStatus.excused: s.excused,
    };
    final colors = {
      AttendanceStatus.present: AppColors.green,
      AttendanceStatus.late: AppColors.sand,
      AttendanceStatus.absent: AppColors.clay,
      AttendanceStatus.excused: AppColors.blue,
    };

    return AppCard(
      radius: AppShapes.tileRadius,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BlobAvatar(
                text: entry.initials,
                size: 34,
                background: AppColors.violetTint,
                foreground: AppColors.violet,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final option in AttendanceStatus.values)
                _StatusPill(
                  label: labels[option]!,
                  color: colors[option]!,
                  selected: status == option,
                  onTap: () => onChanged(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : AppColors.surface2,
      borderRadius: AppShapes.pillRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShapes.pillRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
