import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
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
        MaterialPageRoute(
          builder: (_) => const HabitFormScreen(),
        ),
      ),
      child: const Icon(Icons.add),
    ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Halo Routime!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(
                  '${provider.doneToday} dari ${habits.length} selesai hari ini',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: habits.length,
                  itemBuilder: (context, i) {
                    final h = habits[i];
                    final isDone = isDoneToday(h);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading:
                            Icon(Icons.eco, color: Color(h.colorValue)),
                        title: Text(h.name),
                        subtitle: Text('Streak ${currentStreak(h)} hari'),
                        trailing: IconButton(
                          onPressed: () => context
                              .read<HabitProvider>()
                              .toggleToday(h.id),
                          icon: Icon(
                            isDone ? Icons.check_circle : Icons.circle_outlined,
                            color: AppColors.primary,
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