import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/responsive.dart';
import '../widgets/confirm_delete_dialog.dart';

/// Layar Detail penuh (dipakai di HP).
class HabitDetailScreen extends StatelessWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context) {
    final habit = context
        .watch<HabitProvider>()
        .habits
        .where((h) => h.id == habitId)
        .firstOrNull;

    if (habit == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final provider = context.read<HabitProvider>();
              final navigator = Navigator.of(context);

              final confirmed = await confirmDeleteHabit(context, habit.name);
              if (!confirmed) return;

              navigator.pop();
              provider.deleteHabit(habit.id);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: MaxWidth(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: HabitDetailContent(habit: habit),
          ),
        ),
      ),
    );
  }
}

/// Isi detail (streak + kalender bulan ini), tanpa Scaffold.
class HabitDetailContent extends StatelessWidget {
  final Habit habit;
  const HabitDetailContent({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final now = DateTime.now();
    final totalDays = daysInMonth(now.year, now.month);

    // Berapa kotak kosong sebelum tanggal 1 (Senin = 0, ... Minggu = 6)
    final offset = DateTime(now.year, now.month, 1).weekday - 1;

    bool isDone(int day) => habit.doneDates
        .contains(dateKey(DateTime(now.year, now.month, day)));

    var doneCount = 0;
    for (var d = 1; d <= now.day; d++) {
      if (isDone(d)) doneCount++;
    }

    // Warna angka di dalam kotak: gelap jika latarnya terang
    final doneTextColor =
        color.computeLuminance() > 0.4 ? AppColors.text : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Streak saat ini',
                value: '${currentStreak(habit)} hari',
                valueColor: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Streak terpanjang',
                value: '${longestStreak(habit)} hari',
                valueColor: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Judul bulan + jumlah hari selesai
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              '${monthNames[now.month - 1]} ${now.year}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              '$doneCount/${now.day} hari',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Baris nama hari
        Row(
          children: [
            for (final name in dayNames)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Kalender: kotak kosong (offset) lalu satu kotak per hari
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 0; i < offset; i++) const SizedBox.shrink(),
            for (var d = 1; d <= totalDays; d++)
              Container(
                decoration: BoxDecoration(
                  color: d > now.day
                      ? const Color(0xFFEEF3EA) // belum tiba
                      : isDone(d)
                          ? color // selesai
                          : const Color(0xFFDDE7D8), // terlewat
                  borderRadius: BorderRadius.circular(8),
                  border: d == now.day
                      ? Border.all(color: AppColors.text, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$d',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 12,
                    color: d > now.day
                        ? AppColors.muted
                        : isDone(d)
                            ? doneTextColor
                            : AppColors.text,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: valueColor)),
            ),
          ],
        ),
      ),
    );
  }
}