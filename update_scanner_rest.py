import re

path = r'D:\Attendance Tracker\trace\lib\screens\scanner_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the two buttons from the top Row
top_buttons_regex = r'''                                    const SizedBox\(width: 8\),\s*Container\(\s*decoration: BoxDecoration\(\s*color: TraceColors\.warning\.withValues\(alpha: 0\.2\),\s*borderRadius: BorderRadius\.circular\(12\),\s*border: Border\.all\(color: TraceColors\.warning\.withValues\(alpha: 0\.5\)\),\s*\),\s*child: IconButton\(\s*icon: const Icon\(Icons\.timer_off_rounded, color: TraceColors\.warning\),\s*onPressed: _confirmCutOffTime,\s*tooltip: \'End Time-In\',\s*\),\s*\),\s*const SizedBox\(width: 8\),\s*Container\(\s*decoration: BoxDecoration\(\s*color: TraceColors\.error\.withValues\(alpha: 0\.2\),\s*borderRadius: BorderRadius\.circular\(12\),\s*border: Border\.all\(color: TraceColors\.error\.withValues\(alpha: 0\.5\)\),\s*\),\s*child: IconButton\(\s*icon: const Icon\(Icons\.stop_circle_rounded, color: TraceColors\.error\),\s*onPressed: _confirmEndEvent,\s*tooltip: \'End Event\',\s*\),\s*\),'''

content = re.sub(top_buttons_regex, "", content, flags=re.DOTALL)


# Add the two buttons to the bottom area, and move Note closer to scanner
bottom_area_regex = r'''            // Bottom instructions\s*Positioned\(\s*bottom: 0, left: 0, right: 0,\s*child: SafeArea\(\s*child: Padding\(\s*padding: const EdgeInsets\.all\(24\),\s*child: Column\(children: \[\s*Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 20, vertical: 10\),\s*decoration: BoxDecoration\(\s*color: Colors\.white\.withOpacity\(0\.1\),\s*borderRadius: BorderRadius\.circular\(24\),\s*border: Border\.all\(color: Colors\.white\.withOpacity\(0\.15\)\),\s*\),\s*child: Row\(mainAxisSize: MainAxisSize\.min, children: \[\s*const Icon\(Icons\.qr_code_rounded, color: TraceColors\.gold, size: 16\),\s*const SizedBox\(width: 8\),\s*Text\(\'Align the student\\\'s QR Code within the frame\',\s*style: GoogleFonts\.inter\(color: Colors\.white, fontSize: 12, fontWeight: FontWeight\.w500\)\),\s*\]\),\s*\),\s*\]\),\s*\),\s*\),\s*\),'''

new_bottom_area = '''            // Bottom instructions
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.qr_code_rounded, color: TraceColors.gold, size: 16),
                          const SizedBox(width: 8),
                          Text('Align the student\\'s QR Code within the frame',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      if (_selectedEvent != null)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TraceColors.warning.withValues(alpha: 0.2),
                                  foregroundColor: TraceColors.warning,
                                  side: BorderSide(color: TraceColors.warning.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.timer_off_rounded),
                                label: Text('End Time-In', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                onPressed: _isPhaseDisabled(ScanPhase.timeInAm) ? null : _confirmCutOffTime,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TraceColors.error.withValues(alpha: 0.2),
                                  foregroundColor: TraceColors.error,
                                  side: BorderSide(color: TraceColors.error.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.stop_circle_rounded),
                                label: Text('End Event', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                onPressed: _selectedEvent!.status == 'completed' ? null : _confirmEndEvent,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),'''

content = re.sub(bottom_area_regex, new_bottom_area, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
