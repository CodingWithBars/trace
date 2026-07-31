import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/event_service.dart';
import '../../models/event.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AttendanceEventsScreen extends StatelessWidget {
  const AttendanceEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraceColors.offWhite,
      appBar: const TraceAppBar(title: 'Attendance Report'),
      body: FutureBuilder<List<Event>>(
        future: EventService.getAllEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: TraceColors.navyBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading events', style: GoogleFonts.inter(color: TraceColors.error)));
          }
          
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return Center(child: Text('No events found.', style: GoogleFonts.inter(color: TraceColors.medGrey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TraceCard(
                  onTap: () => context.push('/admin/attendance/${event.id}'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.eventName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: TraceColors.navyBlue,
                              ),
                            ),
                          ),
                          StatusChip(label: event.status.toUpperCase(), color: _getStatusColor(event.status)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AttendanceCount(eventId: event.id),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing': return TraceColors.success;
      case 'upcoming': return TraceColors.royalBlue;
      case 'completed': return TraceColors.medGrey;
      default: return TraceColors.medGrey;
    }
  }
}

class _AttendanceCount extends StatelessWidget {
  final String eventId;
  const _AttendanceCount({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('attendance').where('event_id', isEqualTo: eventId).get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Text('Attended: ...', style: GoogleFonts.inter(fontSize: 14, color: TraceColors.medGrey));
        }
        
        final attendedCount = snapshot.data!.docs.map((d) => (d.data() as Map<String, dynamic>)['student_id']).toSet().length;
        
        return Text('Attended: $attendedCount', 
          style: GoogleFonts.inter(fontSize: 14, color: TraceColors.navyBlue, fontWeight: FontWeight.w600)
        );
      },
    );
  }
}
