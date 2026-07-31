class Event {
  final String id; // Firestore document ID
  final String eventName;
  final String description;
  final String venue;
  final DateTime date;
  final DateTime? cutOffTime;
  final bool timeInClosed;

  /// 'WHOLE_DAY', 'AM_ONLY', or 'PM_ONLY'
  final String eventType;

  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final String bannerUrl;

  // Scheduled base times (stored as "HH:mm" strings)
  final String? startTime;
  final String? endTime;
  final String? morningTimeIn;
  final String? morningTimeOut;
  final String? afternoonTimeIn;
  final String? afternoonTimeOut;

  // Auto-computed scan gate windows (stored as "HH:mm" strings)
  final String? amInStart;
  final String? amInEnd;
  final String? amOutStart;
  final String? amOutEnd;
  final String? pmInStart;
  final String? pmInEnd;
  final String? pmOutStart;
  final String? pmOutEnd;

  Event({
    required this.id,
    required this.eventName,
    required this.description,
    required this.venue,
    required this.date,
    this.cutOffTime,
    this.timeInClosed = false,
    required this.eventType,
    required this.status,
    required this.bannerUrl,
    this.startTime,
    this.endTime,
    this.morningTimeIn,
    this.morningTimeOut,
    this.afternoonTimeIn,
    this.afternoonTimeOut,
    this.amInStart,
    this.amInEnd,
    this.amOutStart,
    this.amOutEnd,
    this.pmInStart,
    this.pmInEnd,
    this.pmOutStart,
    this.pmOutEnd,
  });

  /// Legacy fallback: map old isWholeDay bool to eventType string
  static String _resolveEventType(Map<String, dynamic> data) {
    if (data['event_type'] != null) return data['event_type'] as String;
    final isWholeDay = data['is_whole_day'] ?? false;
    if (isWholeDay == true) return 'WHOLE_DAY';
    if (data['afternoon_time_in'] != null && data['morning_time_in'] == null) return 'PM_ONLY';
    return 'AM_ONLY';
  }

  factory Event.fromMap(Map<String, dynamic> data, String documentId) {
    return Event(
      id: documentId,
      eventName: data['event_name'] ?? '',
      description: data['description'] ?? '',
      venue: data['venue'] ?? '',
      date: data['date'] != null ? (data['date'] as dynamic).toDate() : DateTime.now(),
      cutOffTime: data['cut_off_time'] != null ? (data['cut_off_time'] as dynamic).toDate() : null,
      timeInClosed: data['time_in_closed'] ?? false,
      eventType: _resolveEventType(data),
      status: data['status'] ?? 'upcoming',
      bannerUrl: data['banner_url'] ?? '',
      startTime: data['start_time'],
      endTime: data['end_time'],
      morningTimeIn: data['morning_time_in'] ?? data['time_in'],
      morningTimeOut: data['morning_time_out'] ?? data['time_out'],
      afternoonTimeIn: data['afternoon_time_in'],
      afternoonTimeOut: data['afternoon_time_out'],
      amInStart: data['am_in_start'],
      amInEnd: data['am_in_end'],
      amOutStart: data['am_out_start'],
      amOutEnd: data['am_out_end'],
      pmInStart: data['pm_in_start'],
      pmInEnd: data['pm_in_end'],
      pmOutStart: data['pm_out_start'],
      pmOutEnd: data['pm_out_end'],
    );
  }

  /// Convenience getters
  bool get isWholeDay => eventType == 'WHOLE_DAY';
  bool get isAmOnly => eventType == 'AM_ONLY';
  bool get isPmOnly => eventType == 'PM_ONLY';

  String get computedStatus {
    if (status == 'completed' || status == 'cancelled') return status;
    
    final endStr = endTime ?? afternoonTimeOut ?? morningTimeOut;
    final startStr = startTime ?? morningTimeIn ?? afternoonTimeIn;
    
    if (endStr == null || endStr.isEmpty) return status;
    
    try {
      final endParts = endStr.split(':');
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      final endDateTime = DateTime(date.year, date.month, date.day, endHour, endMinute);
      
      final now = DateTime.now();
      
      if (now.isAfter(endDateTime)) {
        return 'completed';
      }
      
      if (startStr != null && startStr.isNotEmpty) {
        final startParts = startStr.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        final startDateTime = DateTime(date.year, date.month, date.day, startHour, startMinute);
        
        if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
          return 'ongoing';
        }
      }
    } catch (_) {}
    
    return status;
  }

  Map<String, dynamic> toMap() {
    return {
      'event_name': eventName,
      'description': description,
      'venue': venue,
      'date': date,
      'cut_off_time': cutOffTime,
      'time_in_closed': timeInClosed,
      'event_type': eventType,
      'status': status,
      'banner_url': bannerUrl,
      'start_time': startTime,
      'end_time': endTime,
      'morning_time_in': morningTimeIn,
      'morning_time_out': morningTimeOut,
      'afternoon_time_in': afternoonTimeIn,
      'afternoon_time_out': afternoonTimeOut,
      'am_in_start': amInStart,
      'am_in_end': amInEnd,
      'am_out_start': amOutStart,
      'am_out_end': amOutEnd,
      'pm_in_start': pmInStart,
      'pm_in_end': pmInEnd,
      'pm_out_start': pmOutStart,
      'pm_out_end': pmOutEnd,
    };
  }
}
