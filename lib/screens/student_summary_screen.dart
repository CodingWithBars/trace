import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/student_service.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import 'dart:convert';

class StudentSummaryScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentSummaryScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentSummaryScreen> createState() => _StudentSummaryScreenState();
}

class _StudentSummaryScreenState extends ConsumerState<StudentSummaryScreen> {
  Student? _student;
  List<Attendance> _attendance = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final student = await StudentService.getStudentByStudentId(widget.studentId);
      if (student == null) {
        setState(() => _error = 'Student not found.');
        return;
      }
      
      final attendanceList = await StudentService.getAttendanceForStudent(student.id);
      
      if (mounted) {
        setState(() {
          _student = student;
          _attendance = attendanceList;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load records.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: TraceColors.navyBlue.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_busy_outlined, color: TraceColors.medGrey, size: 36),
        ),
        const SizedBox(height: 16),
        Text('No Records Found', style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: TraceColors.navyBlue,
        )),
        const SizedBox(height: 8),
        Text('You haven\'t attended any events yet.',
          style: GoogleFonts.inter(fontSize: 13, color: TraceColors.medGrey)),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TraceColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TraceColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: TraceColors.error),
        const SizedBox(width: 16),
        Expanded(
          child: Text(_error!, style: GoogleFonts.inter(color: TraceColors.error, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  Widget _buildResults() {
    return Column(children: [
      // Student info card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [TraceColors.navyBlue, TraceColors.royalBlue],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: TraceColors.navyBlue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: TraceColors.gold, width: 2),
              color: TraceColors.gold.withValues(alpha: 0.15),
            ),
            child: ClipOval(
              child: _student!.avatarUrl.isNotEmpty
                  ? (_student!.avatarUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(_student!.avatarUrl.split(',').last),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Align(
                            alignment: Alignment.center,
                            child: Text(
                              _student!.name.isNotEmpty ? _student!.name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: TraceColors.gold),
                            ),
                          ),
                        )
                      : Image.network(
                          _student!.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Align(
                            alignment: Alignment.center,
                            child: Text(
                              _student!.name.isNotEmpty ? _student!.name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: TraceColors.gold),
                            ),
                          ),
                        ))
                  : Align(
                      alignment: Alignment.center,
                      child: Text(
                        _student!.name.isNotEmpty ? _student!.name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: TraceColors.gold),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_student!.name, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: TraceColors.white,
              )),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.badge_outlined, color: TraceColors.gold, size: 14),
                const SizedBox(width: 4),
                Text(_student!.studentId, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: TraceColors.gold,
                )),
                const SizedBox(width: 12),
                const Icon(Icons.school_outlined, color: TraceColors.white, size: 14),
                const SizedBox(width: 4),
                Text('${_student!.course} - ${_student!.yearLevel}', style: GoogleFonts.inter(
                  fontSize: 13, color: TraceColors.white.withValues(alpha: 0.8),
                )),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      
      Row(
        children: [
          const Icon(Icons.history_rounded, color: TraceColors.navyBlue, size: 20),
          const SizedBox(width: 8),
          Text('Attendance History', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: TraceColors.navyBlue,
          )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TraceColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_attendance.length} Records', style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: TraceColors.navyBlue,
            )),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      if (_attendance.isEmpty)
        _buildEmptyState()
      else
        ..._attendance.map((a) => _attendanceTile(a)),
    ]);
  }

  Widget _attendanceTile(Attendance a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: TraceColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TraceColors.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAttendanceDetails(a),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: TraceColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_rounded, color: TraceColors.royalBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.eventName, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: TraceColors.navyBlue,
                )),
                const SizedBox(height: 4),
                Text('Tap to view details',
                  style: GoogleFonts.inter(fontSize: 11, color: TraceColors.medGrey, fontStyle: FontStyle.italic)),
              ])),
              StatusChip.fromStatus(a.finalStatus),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAttendanceDetails(Attendance a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: TraceColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: TraceColors.lightGrey, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(a.eventName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: TraceColors.navyBlue)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Overall Status:', style: GoogleFonts.inter(fontSize: 14, color: TraceColors.medGrey)),
                  const SizedBox(width: 12),
                  StatusChip.fromStatus(a.finalStatus),
                ],
              ),
              const SizedBox(height: 24),
              if (a.timeInAm != null || a.timeOutAm != null) ...[
                Text('Morning Session', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: TraceColors.navyBlue)),
                const SizedBox(height: 8),
                _buildTimeRow('Time-In:', a.timeInAm),
                _buildTimeRow('Time-Out:', a.timeOutAm),
                const SizedBox(height: 16),
              ],
              if (a.timeInPm != null || a.timeOutPm != null) ...[
                Text('Afternoon Session', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: TraceColors.navyBlue)),
                const SizedBox(height: 8),
                _buildTimeRow('Time-In:', a.timeInPm),
                _buildTimeRow('Time-Out:', a.timeOutPm),
                const SizedBox(height: 16),
              ],
              if (a.timeInAm == null && a.timeOutAm == null && a.timeInPm == null && a.timeOutPm == null)
                Text('No time records available.', style: GoogleFonts.inter(fontSize: 14, color: TraceColors.medGrey)),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTimeRow(String label, DateTime? time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: TraceColors.medGrey)),
          Text(time != null ? _fmt(time) : '--:--', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: TraceColors.navyBlue)),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraceColors.offWhite,
      appBar: TraceAppBar(
        title: 'Attendance Summary',
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final sessionAsync = ref.watch(studentSessionProvider);
              final isLoggedIn = sessionAsync.valueOrNull != null && sessionAsync.valueOrNull!.isNotEmpty;
              
              if (isLoggedIn) {
                return IconButton(
                  onPressed: () {
                    ref.read(studentSessionProvider.notifier).logout();
                    context.go('/');
                  },
                  icon: const Icon(Icons.logout, color: TraceColors.gold, size: 20),
                  tooltip: 'Logout',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: TraceColors.royalBlue),
                  )
                : _error != null
                    ? _buildErrorCard()
                    : _buildResults(),
          ),
        ),
      ),
    );
  }
}
