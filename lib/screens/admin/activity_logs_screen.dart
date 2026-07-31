import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../../services/activity_log_service.dart';
import 'package:intl/intl.dart';

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraceColors.offWhite,
      appBar: AppBar(
        title: Text('Activity Logs', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: TraceColors.white)),
        backgroundColor: TraceColors.navyBlue,
        iconTheme: const IconThemeData(color: TraceColors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ActivityLogService.stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: TraceColors.navyBlue));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No activity logs found.', style: GoogleFonts.inter(color: TraceColors.medGrey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: TraceColors.lightGrey),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final timeString = timestamp != null
                  ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate())
                  : 'Just now';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.history_rounded, size: 24, color: TraceColors.medGrey.withValues(alpha: 0.7)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['message'] ?? 'Unknown action',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: TraceColors.navyBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$timeString • by ${data['actor_name'] ?? 'System'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: TraceColors.medGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
