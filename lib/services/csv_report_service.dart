import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

class CsvReportService {
  static String listToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((item) {
        String str = item.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          str = '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\n');
  }

  static void downloadCsv(String csvData, String fileName) {
    // For Web (Since the app runs heavily on Web)
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> generateFundsCsv(List<QueryDocumentSnapshot> docs) async {
    List<List<dynamic>> rows = [];
    
    // Header row
    rows.add(['Date', 'Type', 'Amount (PHP)', 'Description', 'Event ID']);
    
    final dateFormat = DateFormat('MM/dd/yyyy hh:mm a');
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'] != null 
          ? dateFormat.format((data['date'] as Timestamp).toDate()) 
          : '';
      final typeStr = (data['type'] ?? '').toString().toUpperCase();
      final amt = (data['amount'] ?? 0).toDouble();
      final desc = data['description'] ?? '';
      final eventId = data['eventId'] ?? '';
      
      rows.add([dateStr, typeStr, amt, desc, eventId]);
    }
    
    String csv = listToCsv(rows);
    downloadCsv(csv, 'Funds_Ledger_Report.csv');
  }

  static Future<void> generateAttendanceCsv(List<dynamic> attendanceList, Map<String, dynamic> studentsMap) async {
    List<List<dynamic>> rows = [];
    
    // Header row
    rows.add(['Time In', 'Student Name', 'Program', 'Year Level', 'Status']);
    
    final dateFormat = DateFormat('MM/dd/yyyy hh:mm a');
    
    for (var att in attendanceList) {
      final timeStr = dateFormat.format(att.timestamp);
      final studentData = studentsMap[att.studentId] as Map<String, dynamic>? ?? {};
      final name = studentData['name'] ?? 'Unknown';
      final program = studentData['course'] ?? '';
      final year = studentData['year_level'] ?? '';
      final status = att.status;
      
      rows.add([timeStr, name, program, year, status]);
    }
    
    String csv = listToCsv(rows);
    downloadCsv(csv, 'Event_Attendance_Report.csv');
  }
}
