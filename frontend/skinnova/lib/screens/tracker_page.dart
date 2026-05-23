import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skinova_ai_scan_flow.dart';

class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Tracker',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(text: 'Diary'),
              Tab(text: 'Progress'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DiaryTab(),
            SkinovaAiScanFlow(),
          ],
        ),
      ),
    );
  }
}

class DiaryTab extends StatefulWidget {
  const DiaryTab({super.key});

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  String get monthTitle {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[currentMonth.month - 1]} ${currentMonth.year}';
  }

  void previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: previousMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          monthTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: nextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((d) => Text(d,
                          style: GoogleFonts.poppins(color: Colors.grey)))
                      .toList(),
                ),
                const SizedBox(height: 14),
                _RealCalendarGrid(
                  currentMonth: currentMonth,
                  selectedDate: selectedDate,
                  onSelect: (date) {
                    setState(() => selectedDate = date);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Routines',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(text: '+ Another routine', blue: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(text: 'Routine history'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _RoutineCard(),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final bool blue;

  const _ActionButton({required this.text, this.blue = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: blue ? const Color(0xFFEAF6FF) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: blue ? Colors.blue : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dark_mode_outlined, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                'Evening',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Edit')),
            ],
          ),
          Text(
            'Repeats daily',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
          const SizedBox(height: 22),
          Container(
            height: 120,
            width: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.spa_outlined, size: 42, color: Colors.grey),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
                children: const [],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Icon(Icons.keyboard_arrow_down, size: 32)),
        ],
      ),
    );
  }
}

class _RealCalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Function(DateTime) onSelect;

  const _RealCalendarGrid({
    required this.currentMonth,
    required this.selectedDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (_, i) {
        if (i < startOffset) return const SizedBox();

        final day = i - startOffset + 1;
        final date = DateTime(currentMonth.year, currentMonth.month, day);

        final isSelected = date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;

        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return GestureDetector(
          onTap: () => onSelect(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: Colors.black)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
