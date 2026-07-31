import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/shared_widgets.dart';
import 'package:intl/intl.dart';

class ManageAdminsScreen extends ConsumerStatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  ConsumerState<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends ConsumerState<ManageAdminsScreen> {
  void _showAddAdminDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: TraceColors.offWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Add New Admin',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TraceColors.navyBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account for another administrator. They will use this email and password to log in.',
                  style: GoogleFonts.inter(fontSize: 13, color: TraceColors.medGrey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Admin Name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password (min 6 chars)'),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                if (isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  GoldButton(
                    label: 'Create Admin Account',
                    fullWidth: true,
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }
                      if (passwordCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters')),
                        );
                        return;
                      }
                      setModalState(() => isProcessing = true);
                      
                      final authService = ref.read(authServiceProvider);
                      final error = await authService.createAdmin(
                        nameCtrl.text.trim(),
                        emailCtrl.text.trim(),
                        passwordCtrl.text,
                      );
                      
                      if (!ctx.mounted) return;
                      setModalState(() => isProcessing = false);
                      
                      if (error != null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: TraceColors.error),
                        );
                      } else {
                        ActivityLogService.log(
                          action: 'Admin Account Created',
                          message: 'Created new admin account for ${emailCtrl.text.trim()}',
                          actorName: ref.read(authServiceProvider).currentUser?.email ?? 'Admin',
                        );
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Admin created successfully!'), backgroundColor: TraceColors.success),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditAdminDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final emailCtrl = TextEditingController(text: data['email'] ?? '');
    String role = data['role'] ?? 'admin';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: TraceColors.offWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Edit Admin Details', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: TraceColors.navyBlue)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Admin Name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  enabled: false, // Cannot change auth email easily
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'superadmin', child: Text('Superadmin')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() => role = v);
                    }
                  },
                ),
                const SizedBox(height: 32),
                if (isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  GoldButton(
                    label: 'Save Changes',
                    fullWidth: true,
                    onPressed: () async {
                      setModalState(() => isProcessing = true);
                      await doc.reference.update({
                        'name': nameCtrl.text.trim(),
                        'role': role,
                      });
                      if (!ctx.mounted) return;
                      setModalState(() => isProcessing = false);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully'), backgroundColor: TraceColors.success));
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin?'),
        content: const Text('Are you sure you want to delete this admin? They will lose access to the portal immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await doc.reference.delete();
              
              final email = (doc.data() as Map<String, dynamic>)['email'];
              ActivityLogService.log(
                action: 'Admin Deleted',
                message: 'Revoked access for admin $email',
                actorName: ref.read(authServiceProvider).currentUser?.email ?? 'Admin',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin deleted successfully'), backgroundColor: TraceColors.success));
              }
            },
            child: const Text('Delete', style: TextStyle(color: TraceColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '--';
    try {
      final dt = (ts as Timestamp).toDate();
      return DateFormat('MM/dd/yyyy hh:mm a').format(dt);
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = ref.watch(authServiceProvider).currentUser?.email;

    return Scaffold(
      backgroundColor: TraceColors.offWhite,
      appBar: TraceAppBar(
        title: 'Manage Admins',
        showBackButton: true,
        actions: [
          TextButton.icon(
            onPressed: _showAddAdminDialog,
            icon: const Icon(Icons.person_add, color: TraceColors.gold, size: 18),
            label: Text('Add Admin', style: GoogleFonts.inter(color: TraceColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrator Accounts',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TraceColors.navyBlue,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.admins.orderBy('created_at', descending: true).snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No admins found.'));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final isMe = currentEmail != null && currentEmail == data['email'];

                      return TraceCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: TraceColors.navyBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.admin_panel_settings, color: TraceColors.navyBlue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        data['name'] ?? data['email'] ?? '--',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: TraceColors.navyBlue),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: TraceColors.gold, borderRadius: BorderRadius.circular(10)),
                                          child: Text('YOU', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: TraceColors.navyBlue)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Role: ${(data['role'] ?? 'Admin').toString().toUpperCase()}', style: GoogleFonts.inter(fontSize: 12, color: TraceColors.medGrey)),
                                  Text('Added: ${_formatDate(data['created_at'])}', style: GoogleFonts.inter(fontSize: 12, color: TraceColors.medGrey)),
                                ],
                              ),
                            ),
                            if (!isMe) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: TraceColors.navyBlue),
                                onPressed: () => _showEditAdminDialog(doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: TraceColors.error),
                                onPressed: () => _confirmDelete(doc),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
