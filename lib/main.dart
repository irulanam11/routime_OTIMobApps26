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

class RoutimeApp extends StatefulWidget {
  const RoutimeApp({super.key});

  @override
  State<RoutimeApp> createState() => _RoutimeAppState();
}

// Mengamati siklus hidup aplikasi: saat aplikasi kembali ke layar,
// Timer disinkronkan ulang agar tampilan langsung akurat.
class _RoutimeAppState extends State<RoutimeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TimerProvider>().refresh();
    }
  }

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
