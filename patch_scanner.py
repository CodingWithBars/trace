import re

path = r'D:\Attendance Tracker\trace\lib\screens\scanner_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'cloud_firestore.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';")

# Add _confirmCutOffTime method
cut_off_method = '''  Future<void> _confirmCutOffTime() async {
    if (_selectedEvent == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraceColors.offWhite,
        title: Text('End Time-In?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: TraceColors.warning)),
        content: Text('Are you sure you want to end the Time-In phase? Any subsequent scans will be marked as "Late Entry".', style: GoogleFonts.inter(color: TraceColors.medGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: TraceColors.medGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TraceColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('End Time-In', style: GoogleFonts.inter(color: TraceColors.navyBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loadingEvents = true);
      await EventService.updateEvent(_selectedEvent!.id, {'cut_off_time': Timestamp.now()});
      await _loadEvents();
    }
  }

  Future<void> _confirmEndEvent'''

content = content.replace("  Future<void> _confirmEndEvent", cut_off_method)

# Add button
buttons = '''                                  Container(
                                    decoration: BoxDecoration(
                                      color: TraceColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: TraceColors.warning.withValues(alpha: 0.5)),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.timer_off_rounded, color: TraceColors.warning),
                                      onPressed: _confirmCutOffTime,
                                      tooltip: 'End Time-In (Late Entry Mode)',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: TraceColors.error.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: TraceColors.error.withValues(alpha: 0.5)),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.stop_circle_rounded, color: TraceColors.error),
                                      onPressed: _confirmEndEvent,
                                      tooltip: 'End Event',
                                    ),
                                  ),'''

content = re.sub(r'                                  Container\(\n                                    decoration: BoxDecoration\(\n                                      color: TraceColors.error.withValues\(alpha: 0.2\).*?tooltip: \'End Event\',\n                                    \),\n                                  \),', buttons, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
