import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;

    if (habits.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('Belum ada data. Tambahkan kebiasaan dulu.'),
          ),
        ),
      );
    }

    final days = lastDays(7);

    final doneByDay = [
      for (final d in days)
        habits.where((h) => h.doneDates.contains(dateKey(d))).length,
    ];

    final totalDone = doneByDay.fold<int>(0, (sum, n) => sum + n);
    final possible = habits.length * 7;
    final percent = (totalDone * 100 / possible).round();

    final ranking = [...habits]
      ..sort((a, b) => doneInLastDays(b, 7).compareTo(doneInLastDays(a, 7)));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistik',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('7 hari terakhir',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap: kalau tidak muat, teks kedua turun ke baris baru
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 8,
                        children: [
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text('kebiasaan selesai',
                                style: TextStyle(color: AppColors.muted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 170,
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: _Bar(
                                  label: dayNames[days[i].weekday - 1],
                                  fraction: doneByDay[i] / habits.length,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Peringkat kebiasaan',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              for (var i = 0; i < ranking.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ranking[i].name),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: doneInLastDays(ranking[i], 7) / 7,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                                color: Color(ranking[i].colorValue),
                                backgroundColor: const Color(0xFFDDE7D8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('${doneInLastDays(ranking[i], 7)}/7',
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu batang grafik. [fraction] bernilai 0.0 sampai 1.0.
class _Bar extends StatelessWidget {
  final String label;
  final double fraction;
  const _Bar({required this.label, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Expanded: batang memakai sisa tinggi setelah label,
        // jadi tidak pernah overflow walaupun font membesar
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction < 0.04 ? 0.04 : fraction,
              widthFactor: 0.7,
              child: Container(
                decoration: BoxDecoration(
                  color: fraction == 0
                      ? const Color(0xFFDDE7D8)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // FittedBox: label mengecil sendiri kalau tidak muat
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
          
        ),
      ],
    );
  }
}