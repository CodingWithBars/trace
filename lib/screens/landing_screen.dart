import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/auth_service.dart';
import '../models/event.dart';
import 'event_details_full_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  int _announcementTab = 0;
  int _ledgerTab = 0;

  // Map category index to Firestore category string
  static const _categories = ['Upcoming', 'Ongoing', 'Previous', 'Cancelled'];
  static const _ledgerTabs = ['All Transactions', 'Contributions', 'Expenses'];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final authService = ref.watch(authServiceProvider);
    final isAdmin = authService.isLoggedIn;

    return Scaffold(
      backgroundColor: TraceColors.offWhite,
      appBar: TraceAppBar(
        showBackButton: false,
        actions: [
          if (!kIsWeb) ...[
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => context.push('/admin/dashboard'),
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: TraceColors.gold,
                    size: 20,
                  ),
                  tooltip: 'Admin Dashboard',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Consumer(
                  builder: (context, ref, _) {
                    final sessionAsync = ref.watch(studentSessionProvider);
                    final studentId = sessionAsync.valueOrNull;
                    final isLoggedIn =
                        studentId != null && studentId.isNotEmpty;

                    return TextButton.icon(
                      onPressed: () {
                        if (isLoggedIn) {
                          context.push('/student/id/$studentId');
                        } else {
                          context.push('/student-login');
                        }
                      },
                      icon: Icon(
                        isLoggedIn ? Icons.badge_outlined : Icons.login,
                        color: TraceColors.gold,
                        size: 18,
                      ),
                      label: Text(
                        isLoggedIn ? 'My ID' : 'Login',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHero(context, isWide),
              _buildStatsBar(),
              _buildAnnouncementsSection(isWide),
              _buildTransparencySection(isWide),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, bool isWide) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: TraceColors.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: TraceColors.gold.withValues(alpha: 0.12),
                  width: 40,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: TraceColors.gold.withValues(alpha: 0.08),
                  width: 50,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: isWide ? 80 : 52),
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 80),
                          child: _buildHeroText(context),
                        ),
                      ),
                      const SizedBox(width: 60),
                      Expanded(child: _buildUpcomingEventCard(isWide: true)),
                    ],
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildHeroText(context),
                      ),
                      const SizedBox(height: 40),
                      _buildUpcomingEventCard(isWide: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transparent Records\n& Attendance for\nCampus Events',
          style: GoogleFonts.inter(
            fontSize: MediaQuery.of(context).size.width > 800 ? 44 : 30,
            fontWeight: FontWeight.w800,
            color: TraceColors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A modern, real-time system for student attendance tracking, event management, and full financial transparency.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: TraceColors.white.withValues(alpha: 0.75),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        if (kIsWeb)
          _buildWebDownloadButton(context)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GoldButton(
                      label: 'Register for QR Code',
                      icon: Icons.qr_code_2_rounded,
                      onPressed: () => context.push('/register'),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final studentId = ref
                              .read(studentSessionProvider)
                              .valueOrNull;
                          final isLoggedIn =
                              studentId != null && studentId.isNotEmpty;
                          if (isLoggedIn) {
                            context.push('/student/summary/$studentId');
                          } else {
                            context.push('/dashboard');
                          }
                        },
                        icon: const Icon(
                          Icons.person_search_rounded,
                          color: TraceColors.white,
                        ),
                        label: Text(
                          'My Attendance',
                          style: GoogleFonts.inter(
                            color: TraceColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: TraceColors.white,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: GoldButton(
                        label: 'Register for QR Code',
                        icon: Icons.qr_code_2_rounded,
                        onPressed: () => context.push('/register'),
                        fullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final studentId = ref
                              .read(studentSessionProvider)
                              .valueOrNull;
                          final isLoggedIn =
                              studentId != null && studentId.isNotEmpty;
                          if (isLoggedIn) {
                            context.push('/student/summary/$studentId');
                          } else {
                            context.push('/dashboard');
                          }
                        },
                        icon: const Icon(
                          Icons.person_search_rounded,
                          color: TraceColors.white,
                        ),
                        label: Text(
                          'My Attendance',
                          style: GoogleFonts.inter(
                            color: TraceColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: TraceColors.white,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/claim-id'),
              icon: const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: TraceColors.gold,
              ),
              label: Text(
                'Claim My Student ID',
                style: GoogleFonts.inter(
                  color: TraceColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decorationColor: TraceColors.gold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWebDownloadButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width < 600
              ? double.infinity
              : 300,
          child: GoldButton(
            label: 'Download Android APK',
            icon: Icons.android_rounded,
            onPressed: () {
              // TODO: Replace with actual download URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('APK Download link coming soon!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEventCard({required bool isWide}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.db
          .collection('events')
          .where('status', whereIn: ['upcoming', 'ongoing'])
          .orderBy('date')
          .limit(10)
          .snapshots(),
      builder: (ctx, snap) {
        final hasEvents = snap.hasData && snap.data!.docs.isNotEmpty;

        if (!hasEvents) {
          return Padding(
            padding: EdgeInsets.only(
              left: isWide ? 0 : 24,
              right: isWide ? 80 : 24,
            ),
            child: _buildSingleEventCard(null),
          );
        }

        var docs = snap.data!.docs.toList();

        // Filter out events that are older than yesterday (to prevent them from being stuck in "Ongoing" indefinitely)
        final now = DateTime.now();
        final yesterdayMidnight = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp?)?.toDate();
          if (date == null) return false;
          return date.isAfter(yesterdayMidnight);
        }).toList();

        if (docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(
              left: isWide ? 0 : 24,
              right: isWide ? 80 : 24,
            ),
            child: _buildSingleEventCard(null),
          );
        }

        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final dateA =
              (dataA['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateB =
              (dataB['date'] as Timestamp?)?.toDate() ?? DateTime.now();

          final cmp = dateA.compareTo(dateB);
          if (cmp != 0) return cmp;

          final timeInA = dataA['is_whole_day'] == true
              ? dataA['morning_time_in']
              : dataA['time_in'];
          final timeInB = dataB['is_whole_day'] == true
              ? dataB['morning_time_in']
              : dataB['time_in'];

          final tA = timeInA?.toString() ?? '23:59';
          final tB = timeInB?.toString() ?? '23:59';

          return tA.compareTo(tB);
        });

        final topDocs = docs.take(2).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(
            left: isWide ? 0 : 24,
            right: isWide ? 80 : 24,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: topDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isLast = doc == topDocs.last;
                return Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 16),
                  child: _buildSingleEventCard(data),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: fit);
      } catch (_) {
        return Container(color: TraceColors.lightGrey);
      }
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => Container(color: TraceColors.lightGrey),
    );
  }

  Widget _buildSingleEventCard(Map<String, dynamic>? data) {
    final hasEvent = data != null;
    if (!hasEvent) {
      return Container(
        width: 330,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: TraceColors.gold.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
            ),
          ],
        ),
        child: Text(
          'No upcoming events.',
          style: GoogleFonts.inter(
            color: TraceColors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      );
    }

    final event = Event.fromMap(data, '');
    final isOngoing = event.status == 'ongoing';
    final isWholeDay = event.isWholeDay;
    final isAfternoonHalfDay = event.isPmOnly;

    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isOngoing ? TraceColors.success : TraceColors.gold)
              .withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showEventDetails(data),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.bannerUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildBannerImage(event.bannerUrl),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 72,
                      width: double.infinity,
                      child: AutoSizeText(
                        event.eventName,
                        maxLines: 3,
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: TraceColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (event.venue.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: TraceColors.gold,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              event.venue,
                              style: GoogleFonts.inter(
                                color: TraceColors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF1E88E5),
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatDate(event.date),
                            style: GoogleFonts.inter(
                              color: TraceColors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isWholeDay) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Morning / Afternoon',
                            style: GoogleFonts.inter(
                              color: TraceColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '- "Whole day event"',
                            style: GoogleFonts.inter(
                              color: TraceColors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '[Time In] : ${event.morningTimeIn ?? '--'}',
                              style: GoogleFonts.inter(
                                color: TraceColors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            ' | ',
                            style: GoogleFonts.inter(
                              color: TraceColors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '[Time Out] : ${event.morningTimeOut ?? '--'}',
                              style: GoogleFonts.inter(
                                color: TraceColors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Afternoon',
                        style: GoogleFonts.inter(
                          color: TraceColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '[Time In] : ${event.afternoonTimeIn ?? '--'}',
                              style: GoogleFonts.inter(
                                color: TraceColors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            ' | ',
                            style: GoogleFonts.inter(
                              color: TraceColors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '[Time Out] : ${event.afternoonTimeOut ?? '--'}',
                              style: GoogleFonts.inter(
                                color: TraceColors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAfternoonHalfDay ? 'Afternoon' : 'Morning',
                            style: GoogleFonts.inter(
                              color: TraceColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '- "Half day event"',
                            style: GoogleFonts.inter(
                              color: TraceColors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '[Time In] : ${(isAfternoonHalfDay ? event.afternoonTimeIn : event.morningTimeIn) ?? '--'}',
                              style: GoogleFonts.inter(
                                color: TraceColors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            ' | ',
                            style: GoogleFonts.inter(
                              color: TraceColors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '[Time Out] : ${(isAfternoonHalfDay ? event.afternoonTimeOut : event.morningTimeOut) ?? '--'}',
                              style: GoogleFonts.inter(
                                color: TraceColors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> data) {
    final event = Event.fromMap(data, '');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsFullScreen(event: event)),
    );
  }

  // ─── STATS BAR ──────────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.db.collection('students').snapshots(),
      builder: (ctx, studentSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.db.collection('events').snapshots(),
          builder: (ctx, eventSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.db.collection('funds').snapshots(),
              builder: (ctx, fundsSnap) {
                final studentCount = studentSnap.hasData
                    ? studentSnap.data!.docs.length
                    : 0;
                final eventCount = eventSnap.hasData
                    ? eventSnap.data!.docs.length
                    : 0;

                double totalIncome = 0;
                if (fundsSnap.hasData) {
                  for (final d in fundsSnap.data!.docs) {
                    final data = d.data() as Map<String, dynamic>;
                    if (data['type'] == 'income' ||
                        data['type'] == 'contribution') {
                      totalIncome += (data['amount'] ?? 0).toDouble();
                    }
                  }
                }

                return Container(
                  color: TraceColors.navyBlue,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statItem(
                          studentCount.toString(),
                          'Registered\nStudents',
                        ),
                      ),
                      _statDivider(),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => TraceColors
                                    .goldGradient
                                    .createShader(bounds),
                                child: Text(
                                  '₱${_formatAmount(totalIncome)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Collected',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: TraceColors.white.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _statDivider(),
                      Expanded(
                        child: _statItem(eventCount.toString(), 'Events\nHeld'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statItem(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                TraceColors.goldGradient.createShader(bounds),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: TraceColors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: TraceColors.white.withValues(alpha: 0.1),
    );
  }

  // ─── ANNOUNCEMENTS ──────────────────────────────────────────────────────────

  Widget _buildAnnouncementsSection(bool isWide) {
    final double hPadding = isWide ? 80 : 20;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: const BoxDecoration(
                    gradient: TraceColors.goldGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Announcements',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: TraceColors.navyBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Category tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Row(
              children: List.generate(
                _categories.length,
                (i) => GestureDetector(
                  onTap: () => setState(() => _announcementTab = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _announcementTab == i
                          ? TraceColors.navyBlue
                          : TraceColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _announcementTab == i
                            ? TraceColors.gold
                            : TraceColors.lightGrey,
                      ),
                      boxShadow: _announcementTab == i
                          ? [
                              BoxShadow(
                                color: TraceColors.navyBlue.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _categories[i],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _announcementTab == i
                            ? TraceColors.gold
                            : TraceColors.medGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Live announcements stream
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.db
                .collection('announcements')
                .orderBy('date_posted', descending: true)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: TraceColors.royalBlue,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final allDocs = snap.data!.docs;
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String cat = data['category'] ?? 'Upcoming';
                if (data['scheduled_date'] != null) {
                  final scheduled = (data['scheduled_date'] as Timestamp)
                      .toDate();
                  if (cat == 'Upcoming' && !scheduled.isAfter(DateTime.now())) {
                    cat = 'Ongoing';
                    // Update in background
                    doc.reference.update({'category': 'Ongoing'});
                  }
                }
                return cat == _categories[_announcementTab];
              }).toList();

              if (filteredDocs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: TraceColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: TraceColors.lightGrey.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 40,
                            color: TraceColors.lightGrey.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_categories[_announcementTab].toLowerCase()} announcements.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: TraceColors.medGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = data['date_posted'] != null
                          ? _formatDate(
                              (data['date_posted'] as Timestamp).toDate(),
                            )
                          : '';
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 320,
                          child: GestureDetector(
                            onTap: () => _showAnnouncementDetails(data),
                            child: TraceCard(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          TraceColors.royalBlue,
                                          TraceColors.midBlue,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child:
                                        (data['banner_url'] != null &&
                                            data['banner_url']
                                                .toString()
                                                .isNotEmpty)
                                        ? _buildBannerImage(data['banner_url'])
                                        : const Icon(
                                            Icons.campaign_rounded,
                                            color: TraceColors.gold,
                                            size: 24,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: TraceColors.navyBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          date,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: TraceColors.gold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (data['scheduled_date'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              'Scheduled: ${_formatDate((data['scheduled_date'] as Timestamp).toDate())}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: TraceColors.medGrey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          data['content'] ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: TraceColors.navyBlue
                                                .withValues(alpha: 0.7),
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: TraceColors.navyBlue,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (data['banner_url'] != null &&
                  data['banner_url'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    width: double.infinity,
                    child: _buildBannerImage(
                      data['banner_url'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Announcement',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: TraceColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data['date_posted'] != null)
                      Text(
                        _formatDate(
                          (data['date_posted'] as Timestamp).toDate(),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: TraceColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (data['scheduled_date'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Scheduled: ${_formatDate((data['scheduled_date'] as Timestamp).toDate())}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: TraceColors.white.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      data['content'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: TraceColors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TraceColors.gold,
                          foregroundColor: TraceColors.navyBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TRANSPARENCY ────────────────────────────────────────────────────────────

  Widget _buildTransparencySection(bool isWide) {
    final double hPad = isWide ? 80 : 20;
    return Container(
      color: TraceColors.navyBlue,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.db
            .collection('funds')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          final docs = snap.hasData
              ? snap.data!.docs
              : <QueryDocumentSnapshot>[];
          double income = 0, expense = 0;
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            if (data['type'] == 'income' || data['type'] == 'contribution') {
              income += (data['amount'] ?? 0).toDouble();
            } else if (data['type'] == 'expense') {
              expense += (data['amount'] ?? 0).toDouble();
            }
          }

          // Filter by selected tab
          final filteredDocs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            if (_ledgerTab == 0) return true;
            if (_ledgerTab == 1) {
              return data['type'] == 'income' || data['type'] == 'contribution';
            }
            return data['type'] == 'expense';
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: TraceColors.goldGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Transparency Ledger',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: TraceColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Text(
                  'Real-time public record of all Student Council finances.',
                  style: GoogleFonts.inter(
                    color: TraceColors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Row(
                        children: [
                          SizedBox(
                            width: constraints.maxWidth > 500
                                ? (constraints.maxWidth - (hPad * 2) - 24) / 3
                                : 160,
                            child: _financeSummaryCard(
                              'Total Collected',
                              '₱${_formatAmount(income)}',
                              Icons.trending_up_rounded,
                              TraceColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: constraints.maxWidth > 500
                                ? (constraints.maxWidth - (hPad * 2) - 24) / 3
                                : 160,
                            child: _financeSummaryCard(
                              'Total Expenses',
                              '₱${_formatAmount(expense)}',
                              Icons.trending_down_rounded,
                              TraceColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: constraints.maxWidth > 500
                                ? (constraints.maxWidth - (hPad * 2) - 24) / 3
                                : 160,
                            child: _financeSummaryCard(
                              'Net Balance',
                              '₱${_formatAmount(income - expense)}',
                              Icons.account_balance_wallet_rounded,
                              TraceColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    children: List.generate(
                      _ledgerTabs.length,
                      (i) => GestureDetector(
                        onTap: () => setState(() => _ledgerTab = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _ledgerTab == i
                                ? TraceColors.gold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _ledgerTab == i
                                  ? TraceColors.gold
                                  : TraceColors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            _ledgerTabs[i],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _ledgerTab == i
                                  ? TraceColors.navyBlue
                                  : TraceColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Live ledger table
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: TraceColors.gold,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : filteredDocs.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: TraceColors.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'No transactions recorded yet.',
                            style: GoogleFonts.inter(
                              color: TraceColors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: TraceColors.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'DATE',
                                      style: GoogleFonts.inter(
                                        color: TraceColors.gold,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'DESCRIPTION',
                                      style: GoogleFonts.inter(
                                        color: TraceColors.gold,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'AMOUNT',
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.inter(
                                        color: TraceColors.gold,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: Color(0x22FFD700), height: 1),
                            ...filteredDocs.asMap().entries.map((e) {
                              final data =
                                  e.value.data() as Map<String, dynamic>;
                              final isIncome =
                                  data['type'] == 'income' ||
                                  data['type'] == 'contribution';
                              final date = data['date'] != null
                                  ? _formatDateShort(
                                      (data['date'] as Timestamp).toDate(),
                                    )
                                  : '-';
                              return Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _showTransactionDetails(data),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                date,
                                                style: GoogleFonts.inter(
                                                  color: TraceColors.white
                                                      .withValues(alpha: 0.6),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isIncome
                                                        ? Icons
                                                              .arrow_circle_up_rounded
                                                        : Icons
                                                              .arrow_circle_down_rounded,
                                                    size: 14,
                                                    color: isIncome
                                                        ? TraceColors.success
                                                        : TraceColors.error,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      data['description'] ?? '',
                                                      style: GoogleFonts.inter(
                                                        color:
                                                            TraceColors.white,
                                                        fontSize: 13,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${isIncome ? '+' : '-'}₱${_formatAmount((data['amount'] ?? 0).toDouble())}',
                                                textAlign: TextAlign.right,
                                                style: GoogleFonts.inter(
                                                  color: isIncome
                                                      ? const Color(0xFF66BB6A)
                                                      : const Color(0xFFEF5350),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (e.key < filteredDocs.length - 1)
                                    const Divider(
                                      color: Color(0x11FFD700),
                                      height: 1,
                                    ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _financeSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: TraceColors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FOOTER ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      color: TraceColors.black,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Column(
        children: [
          const GoldDivider(),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              ShaderMask(
                shaderCallback: (b) => TraceColors.goldGradient.createShader(b),
                child: Text(
                  'TRACE',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Transparent Records & Attendance for Campus Events',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: TraceColors.white.withValues(alpha: 0.35),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Built by students, for students.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: TraceColors.white.withValues(alpha: 0.3),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => context.push('/privacy-policy'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.inter(
                    color: TraceColors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: TraceColors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/terms-conditions'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Terms & Conditions',
                  style: GoogleFonts.inter(
                    color: TraceColors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Copyright © 2026 trace. All rights reserved.',
            style: GoogleFonts.inter(
              color: TraceColors.white.withValues(alpha: 0.25),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDateShort(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  void _showTransactionDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: TraceColors.navyBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Transaction Details',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TraceColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(
                  'Type',
                  (data['type'] ?? '').toString().toUpperCase(),
                ),
                const SizedBox(height: 8),
                _detailRow('Description', data['description'] ?? ''),
                const SizedBox(height: 8),
                _detailRow(
                  'Amount',
                  '₱${_formatAmount((data['amount'] ?? 0).toDouble())}',
                ),
                const SizedBox(height: 8),
                if (data['date'] != null)
                  _detailRow(
                    'Date',
                    _formatDateShort((data['date'] as Timestamp).toDate()),
                  ),
                Builder(
                  builder: (ctx) {
                    List<String> proofImages = [];
                    if (data['proof_images_base64'] != null) {
                      proofImages = List<String>.from(
                        data['proof_images_base64'],
                      );
                    } else if (data['proof_image_base64'] != null &&
                        data['proof_image_base64'].toString().isNotEmpty) {
                      proofImages = [data['proof_image_base64']];
                    }

                    if (proofImages.isEmpty) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Proof Photo',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: TraceColors.white.withValues(alpha: 0.54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: proofImages
                              .map(
                                (b64) => GestureDetector(
                                  onTap: () => _showFullImage(b64),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(
                                        b64.contains(',')
                                            ? b64.split(',').last
                                            : b64,
                                      ),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: TraceColors.white.withValues(alpha: 0.54),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TraceColors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImage(String base64Str) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(
                    base64Str.contains(',')
                        ? base64Str.split(',').last
                        : base64Str,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
