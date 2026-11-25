import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/responsive.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/progress_ring.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';
import '../providers/timer_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Kebiasaan yang sedang dipilih (hanya dipakai di layar lebar)
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kWideBreakpoint;

        // Jika belum ada yang dipilih (atau yang dipilih sudah dihapus),
        // pakai kebiasaan pertama
        final selected = habits.where((h) => h.id == _selectedId).firstOrNull ??
            (habits.isNotEmpty ? habits.first : null);

        final list = _buildList(context, provider, wide, selected?.id);

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.text,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitFormScreen()),
            ),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      SizedBox(
                        width: 400,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: list,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildDetailPane(context, selected)),
                    ],
                  )
                : Padding(padding: const EdgeInsets.all(24), child: list),
          ),
        );
      },
    );
  }

  // Panel kanan (layar lebar)
  Widget _buildDetailPane(BuildContext context, Habit? selected) {
    if (selected == null) {
      return const Center(
        child: Text('Pilih kebiasaan untuk melihat detailnya',
            style: TextStyle(color: AppColors.muted)),
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
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final habitProvider = context.read<HabitProvider>();
                    final timerProvider = context.read<TimerProvider>();

                    final confirmed = await confirmDeleteHabit(
                      context,
                      selected.name,
                    );

                    if (!confirmed || !context.mounted) return;

                    await habitProvider.deleteHabit(
                      selected.id,
                      timerProvider,
                    );
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

  // Sapaan + kartu progres + daftar kebiasaan
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                ProgressRing(done: done, total: habits.length),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progress hari ini',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        habits.isEmpty
                            ? 'Tambahkan kebiasaan pertamamu'
                            : remaining == 0
                                ? 'Semua selesai hari ini!'
                                : '$remaining kebiasaan lagi untuk hari ini',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: habits.isEmpty
              ? const Center(
                  child: Text('Belum ada kebiasaan. Tekan + untuk menambah.',
                      style: TextStyle(color: AppColors.muted)),
                )
              : ListView.builder(
                  itemCount: habits.length,
                  itemBuilder: (context, i) {
                    final h = habits[i];
                    final isDone = isDoneToday(h);

                    return Dismissible(
                      key: ValueKey(h.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.only(right: 24),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC4566B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) =>
                          confirmDeleteHabit(context, h.name),
                      onDismissed: (_) async {
                        final habitProvider = context.read<HabitProvider>();
                        final timerProvider = context.read<TimerProvider>();

                        await habitProvider.deleteHabit(
                          h.id,
                          timerProvider,
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          selected: wide && h.id == selectedId,
                          selectedTileColor: const Color(0xFFE3F1E5),
                          onTap: () {
                            if (wide) {
                              setState(() => _selectedId = h.id);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HabitDetailScreen(habitId: h.id),
                                ),
                              );
                            }
                          },
                          leading:
                              CircleAvatar(radius: 10, backgroundColor: Color(h.colorValue)),
                          title: Text(h.name),
                          subtitle: Text('Streak ${currentStreak(h)} hari'),
                          trailing: IconButton(
                            onPressed: () => context
                                .read<HabitProvider>()
                                .toggleToday(h.id),
                            icon: Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: AppColors.primary,
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