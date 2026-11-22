import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/confirm_delete_dialog.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat pagi!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                '${provider.doneToday} dari ${habits.length} selesai hari ini',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
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
                      confirmDismiss: (_) => confirmDeleteHabit(context, h.name),
                      onDismissed: (_) =>
                          context.read<HabitProvider>().deleteHabit(h.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HabitDetailScreen(habitId: h.id),
                            ),
                          ),
                          leading: Icon(Icons.eco, color: Color(h.colorValue)),
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
          ),
        ),
      ),
    );
  }
}