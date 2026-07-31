import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/event.dart';
import '../models/attendance.dart';
import 'auth_service.dart';
import 'activity_log_service.dart';

enum ScanPhase { timeInAm, timeOutAm, timeInPm, timeOutPm }

extension ScanPhaseExt on ScanPhase {
  String get label {
    switch (this) {
      case ScanPhase.timeInAm: return 'Morning Time-In';
      case ScanPhase.timeOutAm: return 'Morning Time-Out';
      case ScanPhase.timeInPm: return 'Afternoon Time-In';
      case ScanPhase.timeOutPm: return 'Afternoon Time-Out';
    }
  }
  String get field {
    switch (this) {
      case ScanPhase.timeInAm: return 'time_in_am';
      case ScanPhase.timeOutAm: return 'time_out_am';
      case ScanPhase.timeInPm: return 'time_in_pm';
      case ScanPhase.timeOutPm: return 'time_out_pm';
    }
  }
}

enum ScanResultStatus {
  timeInSuccess,
  timeOutSuccess,
  alreadyTimedIn,
  alreadyTimedOut,
  lateEntry,
  attendanceComplete,
  studentNotFound,
  eventNotActive,
  error,
}

class ScanResult {
  final ScanResultStatus status;
  final String? studentName;
  final String? studentId;
  final DateTime? timestamp;
  final String? message;

  ScanResult({
    required this.status,
    this.studentName,
    this.studentId,
    this.timestamp,
    this.message,
  });
}

class AttendanceService {
  static Future<ScanResult> processScan({
    required String qrHash,
    required Event event,
    required ScanPhase phase,
    bool isOfflineMode = false,
    List<Student>? offlineStudents,
    Map<String, Map<String, dynamic>>? offlineAttendance,
  }) async {
    try {
      Student? student;
      Map<String, dynamic>? attendanceData;
      String? attendanceDocId;

      if (isOfflineMode && offlineStudents != null) {
        final matches = offlineStudents.where((s) => s.qrHash == qrHash).toList();
        if (matches.isEmpty) return ScanResult(status: ScanResultStatus.studentNotFound);
        student = matches.first;

        if (offlineAttendance != null) {
          final existingKey = offlineAttendance.keys.firstWhere(
            (k) => offlineAttendance[k]?['student_id'] == student!.id,
            orElse: () => '',
          );
          if (existingKey.isNotEmpty) {
            attendanceDocId = existingKey;
            attendanceData = offlineAttendance[existingKey];
          }
        }
      } else {
        // 1. Find student by QR hash
        final studentSnap = await FirestoreService.students
            .where('qr_hash', isEqualTo: qrHash)
            .limit(1)
            .get();

        if (studentSnap.docs.isEmpty) {
          return ScanResult(status: ScanResultStatus.studentNotFound);
        }

        student = Student.fromMap(
          studentSnap.docs.first.data() as Map<String, dynamic>,
          studentSnap.docs.first.id,
        );

        // 2. Get or create attendance record
        final attendanceSnap = await FirestoreService.attendance
            .where('event_id', isEqualTo: event.id)
            .where('student_id', isEqualTo: student.id)
            .limit(1)
            .get();
        
        if (attendanceSnap.docs.isNotEmpty) {
          attendanceDocId = attendanceSnap.docs.first.id;
          attendanceData = attendanceSnap.docs.first.data() as Map<String, dynamic>;
        }
      }

      final now = DateTime.now();
      final isLate = event.timeInClosed || (event.cutOffTime != null && now.isAfter(event.cutOffTime!));

      if (attendanceData == null) {
        // First scan — create record
        if (phase == ScanPhase.timeOutAm || phase == ScanPhase.timeOutPm) {
          // Can't time out without timing in first
          return ScanResult(
            status: ScanResultStatus.error,
            studentName: student.name,
            message: 'No Time-In record found. Please Time-In first.',
          );
        }

        final newData = {
          'event_id': event.id,
          'student_id': student.id,
          'student_name': student.name,
          'event_name': event.eventName,
          phase.field: Timestamp.fromDate(now),
          'final_status': _computeStatus(phase, now, event),
          'created_at': FieldValue.serverTimestamp(),
          'is_offline_scan': isOfflineMode,
        };

        if (isOfflineMode) {
          final newDocRef = FirestoreService.attendance.doc();
          if (offlineAttendance != null) offlineAttendance[newDocRef.id] = newData;
          newDocRef.set(newData); // Fire and forget
        } else {
          final newDocRef = await FirestoreService.attendance.add(newData);
          await ActivityLogService.log(
            action: 'attendance_scan',
            message: '${student.name} scanned for ${phase.label} (${event.eventName})',
            entityType: 'attendance',
            entityId: newDocRef.id,
            actorName: 'Scanner',
          );
        }

        return ScanResult(
          status: isLate ? ScanResultStatus.lateEntry : ScanResultStatus.timeInSuccess,
          studentName: student.name,
          studentId: student.studentId,
          timestamp: now,
        );
      }

      // 3. Existing record — update
      if (attendanceData[phase.field] != null) {
        return ScanResult(
          status: (phase == ScanPhase.timeInAm || phase == ScanPhase.timeInPm)
              ? ScanResultStatus.alreadyTimedIn
              : ScanResultStatus.alreadyTimedOut,
          studentName: student.name,
          studentId: student.studentId,
          timestamp: (attendanceData[phase.field] as Timestamp).toDate(),
        );
      }

      // Check if all required slots complete
      final updatedData = {...attendanceData, phase.field: Timestamp.fromDate(now)};
      final finalStatus = _computeStatusFromData(updatedData, phase, now, event);
      updatedData['final_status'] = finalStatus;

      final updateFields = {
        phase.field: Timestamp.fromDate(now),
        'final_status': finalStatus,
        if (isOfflineMode) 'is_offline_scan': true,
      };

      if (isOfflineMode) {
        if (offlineAttendance != null) offlineAttendance[attendanceDocId!] = updatedData;
        FirestoreService.attendance.doc(attendanceDocId).update(updateFields); // Fire and forget
      } else {
        await FirestoreService.attendance.doc(attendanceDocId).update(updateFields);
        await ActivityLogService.log(
          action: 'attendance_scan',
          message: '${student.name} scanned for ${phase.label} (${event.eventName})',
          entityType: 'attendance',
          entityId: attendanceDocId,
          actorName: 'Scanner',
        );
      }

      final isComplete = _isAttendanceComplete(updatedData, event);

      return ScanResult(
        status: isComplete
            ? ScanResultStatus.attendanceComplete
            : (phase == ScanPhase.timeOutAm || phase == ScanPhase.timeOutPm
                ? ScanResultStatus.timeOutSuccess
                : (isLate ? ScanResultStatus.lateEntry : ScanResultStatus.timeInSuccess)),
        studentName: student.name,
        studentId: student.studentId,
        timestamp: now,
      );
    } catch (e) {
      return ScanResult(
        status: ScanResultStatus.error,
        message: 'Error processing scan: ${e.toString()}',
      );
    }
  }

  static String _computeStatus(ScanPhase phase, DateTime now, Event event) {
    // Initial status when first scan is created
    if (event.timeInClosed || (event.cutOffTime != null && now.isAfter(event.cutOffTime!))) return 'Late';
    return 'Incomplete';
  }

  /// New Status Matrix based on eventType
  static String _computeStatusFromData(
      Map<String, dynamic> data, ScanPhase phase, DateTime now, Event event) {
    final hasAmIn = data['time_in_am'] != null;
    final hasAmOut = data['time_out_am'] != null;
    final hasPmIn = data['time_in_pm'] != null;
    final hasPmOut = data['time_out_pm'] != null;

    // Absent: no scans at all
    if (!hasAmIn && !hasAmOut && !hasPmIn && !hasPmOut) return 'Absent';

    switch (event.eventType) {
      case 'WHOLE_DAY':
        // All 4 slots required
        if (hasAmIn && hasAmOut && hasPmIn && hasPmOut) return 'Present';
        return 'Incomplete';
      case 'AM_ONLY':
        // AM in + AM out required
        if (hasAmIn && hasAmOut) return 'Present';
        return 'Incomplete';
      case 'PM_ONLY':
        // PM in + PM out required
        if (hasPmIn && hasPmOut) return 'Present';
        return 'Incomplete';
      default:
        if (hasAmIn && hasAmOut) return 'Present';
        return 'Incomplete';
    }
  }

  static bool _isAttendanceComplete(Map<String, dynamic> data, Event event) {
    final hasAmIn = data['time_in_am'] != null;
    final hasAmOut = data['time_out_am'] != null;
    final hasPmIn = data['time_in_pm'] != null;
    final hasPmOut = data['time_out_pm'] != null;

    switch (event.eventType) {
      case 'WHOLE_DAY':
        return hasAmIn && hasAmOut && hasPmIn && hasPmOut;
      case 'AM_ONLY':
        return hasAmIn && hasAmOut;
      case 'PM_ONLY':
        return hasPmIn && hasPmOut;
      default:
        return hasAmIn && hasAmOut;
    }
  }

  static Future<List<Attendance>> getEventAttendance(String eventId) async {
    final snap = await FirestoreService.attendance
        .where('event_id', isEqualTo: eventId)
        .get();
    return snap.docs.map((d) => Attendance.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
  }
}
