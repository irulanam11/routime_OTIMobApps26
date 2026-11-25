import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'providers/habit_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  final timerProvider = TimerProvider();
  await timerProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HabitProvider(),
        ),
        ChangeNotifierProvider.value(
          value: timerProvider,
        ),
      ],
      child: const RoutimeApp(),
    ),
  );
}

class RoutimeApp extends StatelessWidget {
  const RoutimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}