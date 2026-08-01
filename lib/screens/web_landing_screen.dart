import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Web-Only Marketing / Public Landing Page
// Only shown when kIsWeb == true (enforced via routes.dart redirect)
// ─────────────────────────────────────────────────────────────────────────────

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  // Announcement tab: 0=Upcoming, 1=Ongoing, 2=Previous, 3=Cancelled
  int _announcementTab = 0;
  // Ledger tab: 0=All, 1=Contributions, 2=Expenses
  int _ledgerTab = 0;

  static const _announcementCategories = [
    'Upcoming',
    'Ongoing',
    'Previous',
    'Cancelled',
  ];
  static const _ledgerTabs = ['All Transactions', 'Contributions', 'Expenses'];

  static const String _apkUrl = 'https://tinyurl.com/hvpjv4a5';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraceColors.offWhite,
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNavbar(context),
              _buildHero(context),
              _buildStatsBar(),
              _buildEventsSection(),
              _buildAnnouncementsSection(),
              _buildTransparencySection(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NAVBAR ────────────────────────────────────────────────────────────────

  Widget _buildNavbar(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      color: TraceColors.navyBlue,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 16),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => TraceColors.goldGradient.createShader(b),
            child: Text(
              'trace',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Spacer(),
          if (isWide) ...[
            _navLink(context, 'Events', '#events'),
            const SizedBox(width: 28),
            _navLink(context, 'Announcements', '#announcements'),
            const SizedBox(width: 28),
            _navLink(context, 'Ledger', '#ledger'),
            const SizedBox(width: 28),
          ],
          _downloadButton(small: !isWide),
        ],
      ),
    );
  }

  Widget _navLink(BuildContext context, String label, String anchor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {}, // anchor scroll – handled via scroll controller if needed
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _downloadButton({bool small = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _launchApkDownload,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 18,
            vertical: small ? 8 : 10,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFF5A623)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: TraceColors.gold.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.android_rounded,
                size: 16,
                color: Color(0xFF0D1B3E),
              ),
              SizedBox(width: small ? 4 : 6),
              Text(
                small ? 'Download' : 'Download APK',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0D1B3E),
                  fontWeight: FontWeight.w800,
                  fontSize: small ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchApkDownload() async {
    final uri = Uri.parse(_apkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── HERO ──────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1A3A7C), Color(0xFF0D1B3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -60, right: -60, child: _decorCircle(220, 0.08)),
          Positioned(bottom: -80, left: -80, child: _decorCircle(280, 0.05)),
          Positioned(
            top: 40,
            right: isWide ? 400 : -40,
            child: _decorCircle(120, 0.06),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 80 : 24,
              vertical: isWide ? 100 : 64,
            ),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildHeroContent(context, isWide: true),
                      ),
                      const SizedBox(width: 60),
                      Expanded(flex: 4, child: _buildHeroEventPreview()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroContent(context, isWide: false),
                      const SizedBox(height: 48),
                      _buildHeroEventPreview(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: TraceColors.gold.withValues(alpha: opacity),
          width: size / 5,
        ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, {required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transparent Records\n& Attendance for\nCampus Events',
          style: GoogleFonts.inter(
            fontSize: isWide ? 52 : 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'A modern, real-time system for student attendance tracking,\nevent management, and full financial transparency.',
          style: GoogleFonts.inter(
            fontSize: isWide ? 16 : 14,
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.65,
          ),
        ),
        const SizedBox(height: 40),
        // CTA Buttons
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _launchApkDownload,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF5A623)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: TraceColors.gold.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.android_rounded,
                        color: Color(0xFF0D1B3E),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Download Android APK',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0D1B3E),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Feature pills
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _featurePill(Icons.qr_code_2_rounded, 'QR Code ID'),
            _featurePill(Icons.visibility_rounded, 'Live Attendance'),
            _featurePill(
              Icons.account_balance_wallet_rounded,
              'Finance Ledger',
            ),
          ],
        ),
      ],
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroEventPreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('status', whereIn: ['upcoming', 'ongoing'])
          .orderBy('date')
          .limit(2)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyEventCard();
        }

        final docs = snap.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _heroEventCard(data),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyEventCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TraceColors.gold.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          'No upcoming events.',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _heroEventCard(Map<String, dynamic> data) {
    final event = Event.fromMap(data, '');
    final isOngoing = event.status == 'ongoing';
    final statusColor = isOngoing
        ? const Color(0xFFFFD700)
        : const Color(0xFF4FC3F7);
    final statusLabel = isOngoing ? 'ONGOING' : 'UPCOMING';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.bannerUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 7,
              child: _buildBannerImage(event.bannerUrl),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  event.eventName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.venue.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: TraceColors.gold,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          event.venue,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF4FC3F7),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(event.date),
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS BAR ─────────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (_, studentSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (_, eventSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('funds')
                  .snapshots(),
              builder: (_, fundsSnap) {
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

                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return Container(
                      color: TraceColors.navyBlue,
                      padding: EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: isWide ? 80 : 24,
                      ),
                      child: isWide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem(
                                  studentCount.toString(),
                                  'Registered Students',
                                  Icons.people_rounded,
                                ),
                                _vDivider(),
                                _statItem(
                                  '₱${_formatAmount(totalIncome)}',
                                  'Total Collected',
                                  Icons.monetization_on_rounded,
                                ),
                                _vDivider(),
                                _statItem(
                                  eventCount.toString(),
                                  'Events Held',
                                  Icons.event_rounded,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _statItem(
                                      studentCount.toString(),
                                      'Students',
                                      Icons.people_rounded,
                                    ),
                                    _vDivider(),
                                    _statItem(
                                      eventCount.toString(),
                                      'Events',
                                      Icons.event_rounded,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _statItem(
                                  '₱${_formatAmount(totalIncome)}',
                                  'Total Collected',
                                  Icons.monetization_on_rounded,
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
      },
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: TraceColors.gold.withValues(alpha: 0.7), size: 18),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (b) => TraceColors.goldGradient.createShader(b),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 44,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  // ─── EVENTS SECTION ────────────────────────────────────────────────────────

  Widget _buildEventsSection() {
    return Container(
      color: const Color(0xFFF1F4F9),
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 700;
          final hPad = isWide ? 80.0 : 24.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _sectionHeader(
                  'Upcoming & Ongoing Events',
                  TraceColors.navyBlue,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Text(
                  'Stay informed about events happening on campus.',
                  style: GoogleFonts.inter(
                    color: TraceColors.medGrey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: TraceColors.royalBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  final docs = (snap.data?.docs ?? []).where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    return status == 'upcoming' || status == 'ongoing';
                  }).toList();

                  if (docs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _emptyState(
                        'No upcoming or ongoing events right now.',
                        Icons.event_busy_rounded,
                      ),
                    );
                  }

                  // On mobile: vertical stack. On wide: 2-column wrap.
                  if (isWide) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return SizedBox(
                            width:
                                (constraints.maxWidth - hPad * 2 - 20) /
                                2.clamp(1, 2),
                            child: _eventCard(data),
                          );
                        }).toList(),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _eventCard(data),
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> data) {
    final event = Event.fromMap(data, '');
    Color borderColor;
    Color badgeColor;
    String statusLabel;
    switch (event.status.toLowerCase()) {
      case 'ongoing':
        borderColor = const Color(0xFFFFD700);
        badgeColor = const Color(0xFFFFD700);
        statusLabel = 'Ongoing';
        break;
      case 'upcoming':
        borderColor = const Color(0xFF4FC3F7);
        badgeColor = const Color(0xFF4FC3F7);
        statusLabel = 'Upcoming';
        break;
      default:
        borderColor = TraceColors.medGrey;
        badgeColor = TraceColors.medGrey;
        statusLabel = event.status;
    }

    return Container(
      decoration: BoxDecoration(
        color: TraceColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.bannerUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildBannerImage(event.bannerUrl),
            )
          else
            Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [TraceColors.royalBlue, TraceColors.navyBlue],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.event_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 36,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor == const Color(0xFFFFD700)
                          ? const Color(0xFF8B6800)
                          : badgeColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.eventName,
                  style: GoogleFonts.inter(
                    color: TraceColors.navyBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.venue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: TraceColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          event.venue,
                          style: GoogleFonts.inter(
                            color: TraceColors.medGrey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Color(0xFF4FC3F7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(event.date),
                      style: GoogleFonts.inter(
                        color: TraceColors.medGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ANNOUNCEMENTS ─────────────────────────────────────────────────────────

  Widget _buildAnnouncementsSection() {
    return Container(
      color: TraceColors.white,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 700;
          final hPad = isWide ? 80.0 : 24.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _sectionHeader('Announcements', TraceColors.navyBlue),
              ),
              const SizedBox(height: 20),
              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  children: List.generate(
                    _announcementCategories.length,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _announcementTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _announcementTab == i
                              ? TraceColors.navyBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _announcementTab == i
                                ? TraceColors.gold
                                : TraceColors.lightGrey,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _announcementCategories[i],
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
              const SizedBox(height: 28),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('date_posted', descending: true)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: TraceColors.royalBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final allDocs = snap.data?.docs ?? [];
                  final filtered = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final cat = data['category'] ?? 'Upcoming';
                    return cat == _announcementCategories[_announcementTab];
                  }).toList();

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _emptyState(
                        'No ${_announcementCategories[_announcementTab].toLowerCase()} announcements.',
                        Icons.campaign_outlined,
                      ),
                    );
                  }

                  // On mobile: vertical stack. On wide: multi-column wrap.
                  if (isWide) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: filtered.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return SizedBox(
                            width: constraints.maxWidth > 1200
                                ? (constraints.maxWidth - hPad * 2 - 40) / 3
                                : (constraints.maxWidth - hPad * 2 - 20) / 2,
                            child: _announcementCard(data),
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      children: filtered.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _announcementCard(data),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _announcementCard(Map<String, dynamic> data) {
    final date = data['date_posted'] != null
        ? _formatDate((data['date_posted'] as Timestamp).toDate())
        : '';
    final bannerUrl = data['banner_url']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: TraceColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TraceColors.lightGrey.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bannerUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 7,
              child: _buildBannerImage(bannerUrl),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bannerUrl.isEmpty)
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TraceColors.royalBlue, TraceColors.midBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: TraceColors.gold,
                      size: 22,
                    ),
                  ),
                Text(
                  data['title'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TraceColors.navyBlue,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                if (data['scheduled_date'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Scheduled: ${_formatDate((data['scheduled_date'] as Timestamp).toDate())}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: TraceColors.medGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  data['content'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: TraceColors.navyBlue.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TRANSPARENCY LEDGER ───────────────────────────────────────────────────

  Widget _buildTransparencySection() {
    return Container(
      color: TraceColors.navyBlue,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 700;
          final hPad = isWide ? 80.0 : 24.0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('funds')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              double income = 0, expense = 0;
              for (final d in docs) {
                final data = d.data() as Map<String, dynamic>;
                if (data['type'] == 'income' ||
                    data['type'] == 'contribution') {
                  income += (data['amount'] ?? 0).toDouble();
                } else if (data['type'] == 'expense') {
                  expense += (data['amount'] ?? 0).toDouble();
                }
              }

              final filteredDocs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                if (_ledgerTab == 0) return true;
                if (_ledgerTab == 1) {
                  return data['type'] == 'income' ||
                      data['type'] == 'contribution';
                }
                return data['type'] == 'expense';
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _sectionHeader('Transparency Ledger', Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Text(
                      'Real-time public record of all Student Council finances.',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Summary cards — always a horizontal row, wrap on very small screens
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: LayoutBuilder(
                      builder: (ctx2, c2) {
                        // On very narrow screens wrap to 1-col, otherwise always 3-col row
                        final cardWidth = (c2.maxWidth - 32) / 3;
                        final useRow = cardWidth > 90;
                        if (useRow) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _financeSummaryCard(
                                  'Total Collected',
                                  '₱${_formatAmount(income)}',
                                  Icons.trending_up_rounded,
                                  const Color(0xFF66BB6A),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _financeSummaryCard(
                                  'Total Expenses',
                                  '₱${_formatAmount(expense)}',
                                  Icons.trending_down_rounded,
                                  const Color(0xFFEF5350),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _financeSummaryCard(
                                  'Net Balance',
                                  '₱${_formatAmount(income - expense)}',
                                  Icons.account_balance_wallet_rounded,
                                  TraceColors.gold,
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _financeSummaryCard(
                              'Total Collected',
                              '₱${_formatAmount(income)}',
                              Icons.trending_up_rounded,
                              const Color(0xFF66BB6A),
                            ),
                            const SizedBox(height: 10),
                            _financeSummaryCard(
                              'Total Expenses',
                              '₱${_formatAmount(expense)}',
                              Icons.trending_down_rounded,
                              const Color(0xFFEF5350),
                            ),
                            const SizedBox(height: 10),
                            _financeSummaryCard(
                              'Net Balance',
                              '₱${_formatAmount(income - expense)}',
                              Icons.account_balance_wallet_rounded,
                              TraceColors.gold,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Ledger filter tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Row(
                      children: List.generate(
                        _ledgerTabs.length,
                        (i) => GestureDetector(
                          onTap: () => setState(() => _ledgerTab = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _ledgerTab == i
                                  ? TraceColors.gold
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: _ledgerTab == i
                                    ? TraceColors.gold
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _ledgerTabs[i],
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _ledgerTab == i
                                    ? TraceColors.navyBlue
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: snap.connectionState == ConnectionState.waiting
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
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
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: TraceColors.gold.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No transactions recorded yet.',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: TraceColors.gold.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Table header — hide date column on very small screens
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      if (isWide)
                                        Expanded(
                                          flex: 2,
                                          child: _tableHeader('DATE'),
                                        ),
                                      Expanded(
                                        flex: 4,
                                        child: _tableHeader('DESCRIPTION'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: _tableHeader(
                                          'AMOUNT',
                                          align: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  color: Color(0x22FFD700),
                                  height: 1,
                                ),
                                ...filteredDocs.asMap().entries.map((entry) {
                                  final data =
                                      entry.value.data()
                                          as Map<String, dynamic>;
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
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            if (isWide)
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  date,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
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
                                                        ? const Color(
                                                            0xFF66BB6A,
                                                          )
                                                        : const Color(
                                                            0xFFEF5350,
                                                          ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          data['description'] ??
                                                              '',
                                                          style:
                                                              GoogleFonts.inter(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 13,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        // Show date below description on mobile
                                                        if (!isWide)
                                                          Text(
                                                            date,
                                                            style:
                                                                GoogleFonts.inter(
                                                                  color: Colors
                                                                      .white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.4,
                                                                      ),
                                                                  fontSize: 11,
                                                                ),
                                                          ),
                                                      ],
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
                                                  fontSize: isWide ? 13 : 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (entry.key < filteredDocs.length - 1)
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
    return LayoutBuilder(
      builder: (ctx, c) {
        final compact = c.maxWidth < 140;
        return Container(
          padding: EdgeInsets.all(compact ? 12 : 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: compact ? 16 : 22),
              SizedBox(height: compact ? 6 : 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 16 : 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: compact ? 10 : 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeader(String label, {TextAlign align = TextAlign.left}) {
    return Text(
      label,
      textAlign: align,
      style: GoogleFonts.inter(
        color: TraceColors.gold,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 1.2,
      ),
    );
  }

  // ─── FOOTER ────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: const Color(0xFF060D1F),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: const BoxDecoration(gradient: TraceColors.goldGradient),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (b) => TraceColors.goldGradient.createShader(b),
            child: Text(
              'TRACE',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transparent Records & Attendance for Campus Events',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Built by students, for students.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerLink(context, 'Privacy Policy', '/privacy-policy'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '•',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                ),
              ),
              _footerLink(context, 'Terms & Conditions', '/terms-conditions'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Copyright © 2026 trace. All rights reserved.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(BuildContext context, String label, String route) {
    return TextButton(
      onPressed: () => context.push(route),
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 12,
        ),
      ),
    );
  }

  // ─── SHARED HELPERS ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: const BoxDecoration(gradient: TraceColors.goldGradient),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TraceColors.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 44, color: TraceColors.lightGrey),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                color: TraceColors.medGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          width: double.infinity,
        );
      } catch (_) {
        return Container(color: TraceColors.lightGrey);
      }
    }
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      errorBuilder: (ctx, e, s) => Container(color: TraceColors.lightGrey),
    );
  }

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

  String _formatAmount(double amount) =>
      NumberFormat('#,##0.00', 'en_US').format(amount);
}
