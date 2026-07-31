class Attendance {
  final String id; // Firestore document ID
  final String eventId;
  final String eventName;
  final String studentId;
  final DateTime? timeInAm;
  final DateTime? timeOutAm;
  final DateTime? timeInPm;
  final DateTime? timeOutPm;
  final String finalStatus;

  Attendance({
    required this.id,
    required this.eventId,
    this.eventName = 'Unknown Event',
    required this.studentId,
    this.timeInAm,
    this.timeOutAm,
    this.timeInPm,
    this.timeOutPm,
    required this.finalStatus,
  });

  factory Attendance.fromMap(Map<String, dynamic> data, String documentId) {
    String status = data['final_status'] ?? 'Incomplete';
    final hasAmIn = data['time_in_am'] != null;
    final hasAmOut = data['time_out_am'] != null;
    final hasPmIn = data['time_in_pm'] != null;
    final hasPmOut = data['time_out_pm'] != null;

    // Migrate legacy status values to new canonical values
    const legacyPresent = ['complete', 'whole_day_complete', 'morning_complete', 'pm_complete'];
    const legacyIncomplete = ['partial', 'morning_in', 'pm_in', 'late'];
    if (legacyPresent.contains(status.toLowerCase())) {
      status = 'Present';
    } else if (legacyIncomplete.contains(status.toLowerCase())) {
      // Re-evaluate: if all required timestamps exist, make it Present
      if (hasAmIn && hasAmOut && hasPmIn && hasPmOut) {
        status = 'Present';
      } else if ((hasAmIn && hasAmOut) || (hasPmIn && hasPmOut)) {
        // Check single-session events
        status = 'Present';
      } else {
        status = 'Incomplete';
      }
    }

    return Attendance(
      id: documentId,
      eventId: data['event_id'] ?? '',
      eventName: data['event_name'] ?? 'Unknown Event',
      studentId: data['student_id'] ?? '',
      timeInAm: hasAmIn ? (data['time_in_am'] as dynamic).toDate() : null,
      timeOutAm: hasAmOut ? (data['time_out_am'] as dynamic).toDate() : null,
      timeInPm: hasPmIn ? (data['time_in_pm'] as dynamic).toDate() : null,
      timeOutPm: hasPmOut ? (data['time_out_pm'] as dynamic).toDate() : null,
      finalStatus: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'event_name': eventName,
      'student_id': studentId,
      if (timeInAm != null) 'time_in_am': timeInAm,
      if (timeOutAm != null) 'time_out_am': timeOutAm,
      if (timeInPm != null) 'time_in_pm': timeInPm,
      if (timeOutPm != null) 'time_out_pm': timeOutPm,
      'final_status': finalStatus,
    };
  }
}
