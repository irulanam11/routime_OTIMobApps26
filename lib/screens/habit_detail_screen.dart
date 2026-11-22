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

/// Isi detail (streak + riwayat 30 hari), tanpa Scaffold.
class HabitDetailContent extends StatelessWidget {
  final Habit habit;
  const HabitDetailContent({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final today = DateTime.now();

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
        const Text('30 hari terakhir',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 29; i >= 0; i--)
              Container(
                decoration: BoxDecoration(
                  color: habit.doneDates
                          .contains(dateKey(today.subtract(Duration(days: i))))
                      ? color
                      : const Color(0xFFDDE7D8),
                  borderRadius: BorderRadius.circular(8),
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
            )
          ],
        ),
      ),
    );
  }
}