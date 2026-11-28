import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/stats_utils.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  void _changeMonth(int difference) {
    final now = DateTime.now();

    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + difference,
      1,
    );

    // Tidak mengizinkan kalender melihat bulan mendatang.
    if (nextMonth.year > now.year ||
        (nextMonth.year == now.year && nextMonth.month > now.month)) {
      return;
    }

    setState(() {
      _selectedMonth = nextMonth;
      _selectedDate = nextMonth;
    });
  }

  String _dateLabel(DateTime date) {
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;

    if (habits.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada data Statistik',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan kebiasaan terlebih dahulu '
                    'untuk melihat perkembanganmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Semua angka dihitung SEKALI per build, lalu dipakai ulang.
    final stats = MonthStats.compute(habits, _selectedMonth);
    final ranking = stats.rank(habits);

    final selectedCompletedHabits = habits
        .where((habit) => habit.doneDates.contains(dateKey(_selectedDate)))
        .toList();

    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text(
                'Statistik',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Pantau konsistensi dan perkembanganmu.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),

              const SizedBox(height: 24),

              // RINGKASAN STATISTIK
              Text(
                isCurrentMonth
                    ? 'Ringkasan Bulan Ini'
                    : 'Ringkasan ${monthNames[_selectedMonth.month - 1]}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Penyelesaian',
                      value: '${(stats.completionRate * 100).round()}%',
                      subtitle: 'Dari target harian',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Hari Aktif',
                      value: '${stats.activeDays}',
                      subtitle: 'Hari konsisten',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _SummaryCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'Total Habit Selesai',
                value: '${stats.totalCompleted}',
                subtitle: 'Penyelesaian selama bulan ini',
                horizontal: true,
              ),

              const SizedBox(height: 28),

              // KALENDER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Konsistensi Harian',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: AppColors.primary,
                          ),
                          Text(
                            '${monthNames[_selectedMonth.month - 1]} '
                            '${_selectedMonth.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          IconButton(
                            onPressed: isCurrentMonth
                                ? null
                                : () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: AppColors.primary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // NAMA HARI
                      Row(
                        children: [
                          for (final day in dayNames)
                            Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // TANGGAL KALENDER
                      _buildCalendarGrid(stats),

                      const SizedBox(height: 16),

                      // KETERANGAN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Ada Habit selesai',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F1E5),
                              border: Border.all(color: AppColors.primary),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Tanggal dipilih',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // DETAIL TANGGAL
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dateLabel(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (selectedCompletedHabits.isEmpty)
                        const Text(
                          'Belum ada Habit yang diselesaikan pada tanggal ini.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        )
                      else ...[
                        Text(
                          '${selectedCompletedHabits.length} Habit selesai',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final habit in selectedCompletedHabits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(habit.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    habit.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // GRAFIK PERKEMBANGAN
              const Text(
                'Perkembangan Mingguan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Jumlah Habit yang diselesaikan setiap minggu.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _buildWeeklyChart(stats.weekly),
                ),
              ),

              const SizedBox(height: 28),

              // PERINGKAT HABIT
              const Text(
                'Perkembangan Setiap Habit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Jumlah penyelesaian masing-masing kebiasaan.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),

              for (var i = 0; i < ranking.length; i++)
                _HabitProgressCard(
                  habit: ranking[i],
                  completed: stats.completedFor(ranking[i]),
                  elapsedDays: stats.elapsedDays,
                  rank: i + 1,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // MEMBANGUN GRID KALENDER
  Widget _buildCalendarGrid(MonthStats stats) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    final firstDay = DateTime(year, month, 1);
    final totalDays = daysInMonth(year, month);

    // Kalender dimulai dari Senin.
    final leadingDays = firstDay.weekday - 1;

    final totalCells = ((leadingDays + totalDays + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final day = index - leadingDays + 1;

        if (day < 1 || day > totalDays) {
          return const SizedBox.shrink();
        }

        final date = DateTime(year, month, day);
        final today = DateTime.now();

        final isToday = dateKey(date) == dateKey(today);
        final isSelected = dateKey(date) == dateKey(_selectedDate);
        final isFuture = date.isAfter(
          DateTime(today.year, today.month, today.day),
        );

        final hasCompleted = stats.completedOn(date) > 0;

        return InkWell(
          onTap: isFuture
              ? null
              : () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE3F1E5) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday
                  ? Border.all(color: AppColors.primary, width: 1.3)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isFuture
                        ? AppColors.muted.withValues(alpha: 0.35)
                        : isSelected
                        ? AppColors.primary
                        : AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasCompleted
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // GRAFIK PENYELESAIAN PER MINGGU
  Widget _buildWeeklyChart(List<int> weeklyData) {
    final maxValue = weeklyData.fold<int>(
      0,
      (currentMax, value) => value > currentMax ? value : currentMax,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.primary,
              size: 19,
            ),
            const SizedBox(width: 8),
            Text(
              '${weeklyData.fold<int>(0, (a, b) => a + b)} penyelesaian',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < weeklyData.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      children: [
                        Text(
                          '${weeklyData[i]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: maxValue == 0
                                  ? 0.035
                                  : (weeklyData[i] / maxValue)
                                        .clamp(0.035, 1.0)
                                        .toDouble(),
                              widthFactor: 0.65,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: weeklyData[i] == 0
                                      ? const Color(0xFFDDE7D8)
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'M${i + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// KARTU RINGKASAN
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool horizontal;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: horizontal
            ? Row(
                children: [
                  _iconContainer(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconContainer(),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _iconContainer() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F1E5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 19, color: AppColors.primary),
    );
  }
}

// KARTU PERKEMBANGAN HABIT
class _HabitProgressCard extends StatelessWidget {
  final Habit habit;
  final int completed;
  final int elapsedDays;
  final int rank;

  const _HabitProgressCard({
    required this.habit,
    required this.completed,
    required this.elapsedDays,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final progress = elapsedDays == 0
        ? 0.0
        : (completed / elapsedDays).clamp(0.0, 1.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F1E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  '$completed kali',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: Color(habit.colorValue),
                backgroundColor: const Color(0xFFDDE7D8),
              ),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).round()}% dari target',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
