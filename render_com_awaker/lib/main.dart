import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();

    // Initialize Foreground Task
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_channel_id',
        channelName: 'Foreground Service',
        channelDescription: 'This notification appears when the service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // ms, not used in your timer but required
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Background API Caller',
      notificationText: 'Calling API every 4 minutes...',
      callback: startCallback,
    );
    setState(() => _isRunning = true);
  }

  Future<void> _stopService() async {
    await FlutterForegroundTask.stopService();
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Caller Every 4 min')),
      body: Center(
        child: _isRunning
            ? ElevatedButton(
                onPressed: _stopService,
                child: const Text('Stop Service'),
              )
            : ElevatedButton(
                onPressed: _startService,
                child: const Text('Start Service'),
              ),
      ),
    );
  }
}

/// Background entry point
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final response = await http.get(Uri.parse('https://malayalam-to-english.onrender.com/awake'));
        print('API Response: ${response.statusCode} ${response.body}');
      } catch (e) {
        print('Error calling API: $e');
      }
    });
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    _timer?.cancel();
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {}
}
