import re

path = r'D:\Attendance Tracker\trace\lib\screens\landing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace StreamBuilder logic
new_stream = '''  Widget _buildUpcomingEventCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.db
          .collection('events')
          .where('status', whereIn: ['upcoming', 'ongoing'])
          .orderBy('date')
          .limit(2)
          .snapshots(),
      builder: (ctx, snap) {
        final hasEvents = snap.hasData && snap.data!.docs.isNotEmpty;

        if (!hasEvents) {
          return _buildSingleEventCard(null);
        }

        final docs = snap.data!.docs;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isLast = doc == docs.last;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: _buildSingleEventCard(data),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSingleEventCard(Map<String, dynamic>? data) {
    final hasEvent = data != null;
    final isOngoing = hasEvent && data['status'] == 'ongoing';
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isOngoing ? TraceColors.success : TraceColors.gold).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (hasEvent) {
            _showEventDetails(data);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOngoing ? 'ONGOING EVENT' : 'UPCOMING EVENT',
              style: GoogleFonts.inter(
                color: isOngoing ? TraceColors.success : TraceColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasEvent)
              Text(
                'No upcoming events.',
                style: GoogleFonts.inter(
                  color: TraceColors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              )
            else ...[
              Text('''

content = re.sub(r'  Widget _buildUpcomingEventCard\(\) \{.*?(?=                data!\[\'event_name\'\])', new_stream, content, flags=re.DOTALL)

content = content.replace("data!['event_name']", "data['event_name']")

# fix the gold references in the bottom of the card
gold_replace = '''                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isOngoing ? TraceColors.success : TraceColors.gold).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isOngoing ? TraceColors.success : TraceColors.gold).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      data['is_whole_day'] == true
                          ? 'Whole Day Event'
                          : 'Half Day Event',
                      style: GoogleFonts.inter(
                        color: isOngoing ? TraceColors.success : TraceColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: isOngoing ? TraceColors.success : TraceColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Fully Transparent & Auditable',
                        style: GoogleFonts.inter(
                          color: isOngoing ? TraceColors.success : TraceColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );'''

content = re.sub(r'                  Container\(\n                    padding: const EdgeInsets.symmetric\(\n                      horizontal: 10,\n                      vertical: 4,\n                    \),\n                    decoration: BoxDecoration\(\n                      color: TraceColors.gold.withValues\(alpha: 0.15\).*?        \);', gold_replace, content, flags=re.DOTALL)


with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
