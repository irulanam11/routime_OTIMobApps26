import 'package:material_ui/material_ui.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data dummy sementara. Hari 3 diganti Provider.
  final List<Habit> _habits = [
    Habit(
      id: '1',
      name: 'Minum 8 gelas air',
      colorValue: 0xFF2F7D4F,
      doneDates: {
        for (var i = 0; i < 12; i++)
          dateKey(DateTime.now().subtract(Duration(days: i)))
      },
    ),
    Habit(id: '2', name: 'Baca 15 menit', colorValue: 0xFF2F7D4F),
    Habit(id: '3', name: 'Belajar Flutter', colorValue: 0xFF2F7D4F),
  ];

  void _toggle(Habit h) {
    final key = dateKey(DateTime.now());
    setState(() {
      h.doneDates.contains(key) ? h.doneDates.remove(key) : h.doneDates.add(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _habits.where(isDoneToday).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selamat pagi!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('$done dari ${_habits.length} selesai hari ini',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _habits.length,
                  itemBuilder: (context, i) {
                    final h = _habits[i];
                    final isDone = isDoneToday(h);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.eco, color: AppColors.primary),
                        title: Text(h.name),
                        subtitle: Text('Streak ${currentStreak(h)} hari'),
                        trailing: IconButton(
                          onPressed: () => _toggle(h),
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