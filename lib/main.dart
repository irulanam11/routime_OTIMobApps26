import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'providers/habit_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => HabitProvider(),
        child: const RoutimeApp(),
      ),
    );

class RoutimeApp extends StatelessWidget {
  const RoutimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}