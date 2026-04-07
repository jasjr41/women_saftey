import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(PowerButtonTaskHandler());
}

class PowerButtonTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

class PowerButtonService {
  static const MethodChannel _channel =
  MethodChannel('com.example.womens_safety_app/power_button');

  static int _pressCount = 0;
  static DateTime? _lastPressTime;
  static const int requiredPresses = 4;
  static const Duration resetDuration = Duration(seconds: 2);

  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sos_trigger_channel',
        channelName: 'SOS Trigger Service',
        channelDescription: 'Listening for emergency SOS trigger',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
      ),
    );
  }

  // 👇 Call this from main.dart with a callback
  static void listenForPowerButton(Function() onSOSTriggered) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'powerButtonPressed') {
        _handlePress(onSOSTriggered);
      }
    });
  }

  static void _handlePress(Function() onSOSTriggered) {
    final now = DateTime.now();

    if (_lastPressTime != null &&
        now.difference(_lastPressTime!) > resetDuration) {
      _pressCount = 0;
    }

    _pressCount++;
    _lastPressTime = now;
    print('🔘 Power button pressed: $_pressCount/$requiredPresses');

    if (_pressCount >= requiredPresses) {
      _pressCount = 0;
      onSOSTriggered();
    }
  }

  static Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: "Women's Safety Active",
      notificationText: 'Press power button 4x for SOS',
      callback: startCallback,
    );
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}