import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/responsive.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/progress_ring.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kWideBreakpoint;

        final selected =
            habits.where((h) => h.id == _selectedId).firstOrNull ??
            (habits.isNotEmpty ? habits.first : null);

        final list = _buildList(context, provider, wide, selected?.id);

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.text,
            elevation: 5,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HabitFormScreen()),
              );
            },
            child: const Icon(Icons.add_rounded, size: 32),
          ),
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      SizedBox(
                        width: 410,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 20, 20),
                          child: list,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildDetailPane(context, selected)),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 12),
                    child: list,
                  ),
          ),
        );
      },
    );
  }

  // Panel detail untuk tampilan tablet atau layar lebar.
  Widget _buildDetailPane(BuildContext context, Habit? selected) {
    if (selected == null) {
      return const Center(
        child: Text(
          'Pilih kebiasaan untuk melihat detailnya',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: MaxWidth(
        width: 560,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus kebiasaan',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final habitProvider = context.read<HabitProvider>();
                    final timerProvider = context.read<TimerProvider>();

                    final confirmed = await confirmDeleteHabit(
                      context,
                      selected.name,
                    );

                    if (!confirmed || !context.mounted) return;

                    await habitProvider.deleteHabit(selected.id, timerProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: HabitDetailContent(habit: selected),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Halaman utama: sapaan, progress, dan daftar Habit.
  Widget _buildList(
    BuildContext context,
    HabitProvider provider,
    bool wide,
    String? selectedId,
  ) {
    final habits = provider.habits;
    final done = provider.doneToday;
    final remaining = habits.length - done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),

        const SizedBox(height: 24),

        // Kartu progress harian.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              ProgressRing(done: done, total: habits.length),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress hari ini',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      habits.isEmpty
                          ? 'Tambahkan kebiasaan pertamamu'
                          : remaining == 0
                          ? 'Semua kebiasaan selesai hari ini!'
                          : '$remaining kebiasaan lagi untuk hari ini',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Daftar Habit.
        Expanded(
          child: habits.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada kebiasaan. Tekan + untuk menambah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 2, bottom: 100),
                  itemCount: habits.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final isDone = isDoneToday(habit);

                    return Dismissible(
                      key: ValueKey(habit.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC4566B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) {
                        return confirmDeleteHabit(context, habit.name);
                      },
                      onDismissed: (_) async {
                        await context.read<HabitProvider>().deleteHabit(
                          habit.id,
                          context.read<TimerProvider>(),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: wide && habit.id == selectedId
                              ? Border.all(color: AppColors.primary, width: 1.2)
                              : null,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (wide) {
                              setState(() {
                                _selectedId = habit.id;
                              });
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HabitDetailScreen(habitId: habit.id),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 17,
                            ),
                            child: Row(
                              children: [
                                // Penanda warna Habit.
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Color(habit.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                // Nama dan streak Habit.
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        habit.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Streak ${currentStreak(habit)} hari',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Tombol tandai selesai.
                                IconButton(
                                  tooltip: isDone
                                      ? 'Batalkan penyelesaian'
                                      : 'Tandai selesai',
                                  onPressed: () {
                                    context.read<HabitProvider>().toggleToday(
                                      habit.id,
                                    );
                                  },
                                  icon: Icon(
                                    isDone
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: AppColors.primary,
                                    size: 25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
