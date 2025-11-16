import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';

class ServiceTestPage extends StatefulWidget {
  const ServiceTestPage({super.key});

  @override
  State<ServiceTestPage> createState() => _ServiceTestPageState();
}

class _ServiceTestPageState extends State<ServiceTestPage> {
  final service = FlutterBackgroundService();

  String log = "";
  void addLog(String text) {
    setState(() => log += "$text\n");
    print(text);
  }

  Future<void> _restartService() async {
    addLog("⛔ Stopping existing service...");
    service.invoke("stop");
    await Future.delayed(const Duration(milliseconds: 400));

    addLog("🔄 Starting fresh instance...");
    await service.startService();
    await Future.delayed(const Duration(seconds: 1));

    final running = await service.isRunning();
    addLog("Service running: $running");
  }

  Future<void> _runTest() async {
    addLog("-------------------------------");
    addLog("🧪 TEST START");

    await _restartService();

    addLog("📤 Sending start_timer...");
    service.invoke("start_timer", {
      "duration": 300, // 5 min
      "sessionType": "work",
    });

    await Future.delayed(const Duration(seconds: 1));
    addLog("🧩 TEST COMPLETE");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Service Test")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _runTest,
            child: const Text("Run Test"),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(log),
            ),
          )
        ],
      ),
    );
  }
}
