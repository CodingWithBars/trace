import re

path = r'D:\Attendance Tracker\trace\lib\screens\scanner_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _confirmCutOffTime dialog to match button rename if needed
content = content.replace("End Time-In (Late Entry Mode)", "End Time-In")

# 2. Add _getPhaseLabel and _isPhaseDisabled to _ScannerScreenState
helper_methods = '''  String _getPhaseLabel(ScanPhase p) {
    if (_selectedEvent == null) return p.label;
    if (_selectedEvent!.isWholeDay) return p.label;
    
    if (p == ScanPhase.timeInAm) {
      if (_selectedEvent!.timeIn?.toLowerCase().contains('pm') == true) return 'Afternoon Time-In';
      return 'Morning Time-In';
    }
    if (p == ScanPhase.timeOutAm) {
      final tOut = _selectedEvent!.timeOut?.toLowerCase() ?? '';
      if (tOut.startsWith('12:') && tOut.contains('pm')) return 'Noon Time-Out';
      if (tOut.contains('pm')) return 'Afternoon Time-Out';
      return 'Morning Time-Out';
    }
    return p.label;
  }

  bool _isPhaseDisabled(ScanPhase p) {
    if (_selectedEvent == null) return false;
    if (p == ScanPhase.timeInAm || p == ScanPhase.timeInPm) {
       return DateTime.now().isAfter(_selectedEvent!.cutOffTime);
    }
    if (p == ScanPhase.timeOutAm || p == ScanPhase.timeOutPm) {
       return _selectedEvent!.status == 'completed';
    }
    return false;
  }

  Future<void> _confirmCutOffTime'''

content = content.replace("  Future<void> _confirmCutOffTime", helper_methods)

# 3. Update the phase button builder to use _getPhaseLabel and _isPhaseDisabled
phase_button_regex = r'''children: ScanPhase\.values\s*\.where\(\(p\) => _selectedEvent == null \|\| _selectedEvent!\.isWholeDay \|\| \(p == ScanPhase\.timeInAm \|\| p == ScanPhase\.timeOutAm\)\)\s*\.map\(\(p\) => GestureDetector\(\s*onTap: \(\) => setState\(\(\) => _selectedPhase = p\),\s*child: Container\(\s*margin: const EdgeInsets\.only\(right: 8\),\s*padding: const EdgeInsets\.symmetric\(horizontal: 14, vertical: 8\),\s*decoration: BoxDecoration\(\s*color: _selectedPhase == p \? TraceColors\.gold : Colors\.white\.withValues\(alpha: 0\.12\),\s*borderRadius: BorderRadius\.circular\(20\),\s*border: Border\.all\(\s*color: _selectedPhase == p \? TraceColors\.gold : Colors\.white\.withValues\(alpha: 0\.2\),\s*\),\s*\),\s*child: Text\(p\.label, style: GoogleFonts\.inter\(\s*fontSize: 12, fontWeight: FontWeight\.w600,\s*color: _selectedPhase == p \? TraceColors\.navyBlue : Colors\.white,\s*\)\),\s*\),\s*\)\)\.toList\(\),'''

new_phase_buttons = '''children: ScanPhase.values
                              .where((p) => _selectedEvent == null || _selectedEvent!.isWholeDay || (p == ScanPhase.timeInAm || p == ScanPhase.timeOutAm))
                              .map((p) {
                            final disabled = _isPhaseDisabled(p);
                            return GestureDetector(
                              onTap: disabled ? null : () => setState(() => _selectedPhase = p),
                              child: Opacity(
                                opacity: disabled ? 0.4 : 1.0,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedPhase == p ? TraceColors.gold : Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedPhase == p ? TraceColors.gold : Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(_getPhaseLabel(p), style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: _selectedPhase == p ? TraceColors.navyBlue : Colors.white,
                                  )),
                                ),
                              ),
                            );
                          }).toList(),'''

content = re.sub(phase_button_regex, new_phase_buttons, content, flags=re.DOTALL)


# 4. Remove the two buttons from the top Row
top_buttons_regex = r'''                                    const SizedBox\(width: 8\),\s*Container\(\s*decoration: BoxDecoration\(\s*color: TraceColors\.warning\.withValues\(alpha: 0\.2\),\s*borderRadius: BorderRadius\.circular\(12\),\s*border: Border\.all\(color: TraceColors\.warning\.withValues\(alpha: 0\.5\)\),\s*\),\s*child: IconButton\(\s*icon: const Icon\(Icons\.timer_off_rounded, color: TraceColors\.warning\),\s*onPressed: _confirmCutOffTime,\s*tooltip: \'End Time-In\',\s*\),\s*\),\s*const SizedBox\(width: 8\),\s*Container\(\s*decoration: BoxDecoration\(\s*color: TraceColors\.error\.withValues\(alpha: 0\.2\),\s*borderRadius: BorderRadius\.circular\(12\),\s*border: Border\.all\(color: TraceColors\.error\.withValues\(alpha: 0\.5\)\),\s*\),\s*child: IconButton\(\s*icon: const Icon\(Icons\.stop_circle_rounded, color: TraceColors\.error\),\s*onPressed: _confirmEndEvent,\s*tooltip: \'End Event\',\s*\),\s*\),'''

content = re.sub(top_buttons_regex, "", content, flags=re.DOTALL)


# 5. Add the two buttons to the bottom area, and move Note closer to scanner
bottom_area_regex = r'''            // Bottom instructions\s*Positioned\(\s*bottom: 0, left: 0, right: 0,\s*child: SafeArea\(\s*child: Padding\(\s*padding: const EdgeInsets\.all\(24\),\s*child: Column\(\s*children: \[\s*Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 20, vertical: 10\),\s*decoration: BoxDecoration\(\s*color: Colors\.white\.withOpacity\(0\.1\),\s*borderRadius: BorderRadius\.circular\(24\),\s*border: Border\.all\(color: Colors\.white\.withOpacity\(0\.15\)\),\s*\),\s*child: Row\(mainAxisSize: MainAxisSize\.min, children: \[\s*const Icon\(Icons\.qr_code_rounded, color: TraceColors\.gold, size: 16\),\s*const SizedBox\(width: 8\),\s*Text\(\'Align the student\\\'s QR Code within the frame\',\s*style: GoogleFonts\.inter\(color: Colors\.white, fontSize: 12, fontWeight: FontWeight\.w500\)\),\s*\]\),\s*\),\s*\]\),\s*\),\s*\),\s*\),'''

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
