import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String _selectedProgram = 'All';
  bool _sortAscending = true;
  final List<String> _programs = ['All', 'BSBA', 'BSA', 'BTLED', 'BSIT'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraceColors.offWhite,
      appBar: AppBar(
        backgroundColor: TraceColors.navyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: TraceColors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'List of Students',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: TraceColors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Container(
              color: TraceColors.navyBlue,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: _programs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final program = entry.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedProgram = program),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: i == _programs.length - 1 ? 0 : 8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedProgram == program
                              ? TraceColors.gold
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: _selectedProgram == program
                              ? null
                              : Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          program,
                          style: GoogleFonts.inter(
                            color: _selectedProgram == program
                                ? TraceColors.navyBlue
                                : TraceColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // slightly smaller to fit 5 items
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.db.collection('students').snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDocs = snap.data?.docs ?? [];
                  final filteredDocs = _selectedProgram == 'All'
                      ? allDocs
                      : allDocs.where((doc) {
                          final course =
                              (doc.data() as Map<String, dynamic>)['course']
                                  ?.toString()
                                  .toUpperCase() ??
                              '';
                          return course == _selectedProgram;
                        }).toList();

                  filteredDocs.sort((a, b) {
                    final nameA =
                        ((a.data() as Map<String, dynamic>)['name'] ?? '')
                            .toString()
                            .toLowerCase();
                    final nameB =
                        ((b.data() as Map<String, dynamic>)['name'] ?? '')
                            .toString()
                            .toLowerCase();
                    return _sortAscending
                        ? nameA.compareTo(nameB)
                        : nameB.compareTo(nameA);
                  });

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              'Total Student: ${filteredDocs.length}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: TraceColors.navyBlue,
                              ),
                            ),
                            const Spacer(),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<bool>(
                                value: _sortAscending,
                                icon: const Icon(
                                  Icons.sort_by_alpha,
                                  size: 20,
                                  color: TraceColors.navyBlue,
                                ),
                                isDense: true,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: TraceColors.navyBlue,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: true,
                                    child: Text('A-Z'),
                                  ),
                                  DropdownMenuItem(
                                    value: false,
                                    child: Text('Z-A'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _sortAscending = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filteredDocs.isEmpty
                            ? Center(
                                child: Text(
                                  'No students found for this program.',
                                  style: GoogleFonts.inter(
                                    color: TraceColors.medGrey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredDocs.length,
                                itemBuilder: (ctx, i) {
                                  final data =
                                      filteredDocs[i].data()
                                          as Map<String, dynamic>;
                                  final name = data['name'] ?? 'Unknown';
                                  final course = data['course'] ?? '';
                                  final year = data['year_level'] ?? '';
                                  final studentId = data['student_id'] ?? '';
                                  final avatarUrl = data['avatar_url'] ?? '';
                                  final initials = name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: TraceColors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: TraceColors.navyBlue
                                              .withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: TraceColors.royalBlue
                                              .withValues(alpha: 0.1),
                                          backgroundImage: _getAvatarProvider(
                                            avatarUrl,
                                          ),
                                          child: avatarUrl.isEmpty
                                              ? Text(
                                                  initials,
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        TraceColors.royalBlue,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: TraceColors.navyBlue,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$course | $year | $studentId',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
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
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getAvatarProvider(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }
}
