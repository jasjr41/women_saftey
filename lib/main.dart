import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';
import 'services/power_button_service.dart';
import 'services/alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PowerButtonService.initialize();
  runApp(const WomenSafetyApp());
}

class WomenSafetyApp extends StatefulWidget {
  const WomenSafetyApp({super.key});

  @override
  State<WomenSafetyApp> createState() => _WomenSafetyAppState();
}

class _WomenSafetyAppState extends State<WomenSafetyApp> {
  final AlertService _alertService = AlertService();
  late final DataCallback _sosCallback;  // 👈 store callback reference

  @override
  void initState() {
    super.initState();
    _startPowerButtonService();
    // 👇 simpler - no more DataCallback issue
    PowerButtonService.listenForPowerButton(() {
      if (context.mounted) {
        _alertService.sendSOSAlert(context);
      }
    });
  }

  void _startPowerButtonService() async {
    await PowerButtonService.startService();
  }

  void _listenForSOSTrigger() {
    _sosCallback = (data) {
      if (data == 'TRIGGER_SOS') {
        debugPrint('🚨 SOS triggered via power button!');
        if (context.mounted) {
          _alertService.sendSOSAlert(context);
        }
      }
    };
    FlutterForegroundTask.addTaskDataCallback(_sosCallback);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_sosCallback); // 👈 correct type
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp(
        title: 'Women\'s Safety',
        theme: ThemeData(
          primarySwatch: Colors.pink,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryPink,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.darkText),
            titleTextStyle: TextStyle(
              color: AppColors.darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}