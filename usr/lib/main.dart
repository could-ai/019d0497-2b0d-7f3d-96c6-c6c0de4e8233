import 'package:flutter/material.dart';
import 'circuit_simulator.dart';

void main() {
  runApp(const VWBeetleWiringApp());
}

class VWBeetleWiringApp extends StatelessWidget {
  const VWBeetleWiringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1960 VW Beetle Wiring Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainSimulatorScreen(),
      },
    );
  }
}

class MainSimulatorScreen extends StatefulWidget {
  const MainSimulatorScreen({super.key});

  @override
  State<MainSimulatorScreen> createState() => _MainSimulatorScreenState();
}

class _MainSimulatorScreenState extends State<MainSimulatorScreen> {
  // Circuit States
  bool isBatteryConnected = true;
  int ignitionState = 0; // 0: Off, 1: On, 2: Start
  bool isLightSwitchOn = false;
  bool isEngineRunning = false;

  void _toggleBattery() {
    setState(() {
      isBatteryConnected = !isBatteryConnected;
      if (!isBatteryConnected) {
        ignitionState = 0;
        isLightSwitchOn = false;
        isEngineRunning = false;
      }
    });
  }

  void _cycleIgnition() {
    if (!isBatteryConnected) return;
    setState(() {
      ignitionState = (ignitionState + 1) % 3;
      if (ignitionState == 2) {
        // Cranking
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && ignitionState == 2) {
            setState(() {
              ignitionState = 1; // Return to 'On'
              isEngineRunning = true;
            });
          }
        });
      } else if (ignitionState == 0) {
        isEngineRunning = false;
      }
    });
  }

  void _toggleLights() {
    if (!isBatteryConnected) return;
    setState(() {
      isLightSwitchOn = !isLightSwitchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1960 VW Beetle Wiring Simulator (6V)'),
        backgroundColor: const Color(0xFF2D2D30),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Control Panel
          Container(
            width: 300,
            color: const Color(0xFF252526),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Controls',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildSwitch(
                  'Battery Disconnect',
                  isBatteryConnected,
                  _toggleBattery,
                  activeColor: Colors.green,
                ),
                const Divider(),
                _buildIgnitionControl(),
                const Divider(),
                _buildSwitch(
                  'Headlight Switch',
                  isLightSwitchOn,
                  _toggleLights,
                  activeColor: Colors.blue,
                ),
                const Spacer(),
                _buildStatusPanel(),
              ],
            ),
          ),
          // Interactive Schematic
          Expanded(
            child: CircuitSimulator(
              isBatteryConnected: isBatteryConnected,
              ignitionState: ignitionState,
              isLightSwitchOn: isLightSwitchOn,
              isEngineRunning: isEngineRunning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, VoidCallback onChanged, {Color? activeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: (val) => onChanged(),
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildIgnitionControl() {
    String stateText = 'OFF';
    Color stateColor = Colors.grey;
    if (ignitionState == 1) {
      stateText = 'ON';
      stateColor = Colors.orange;
    } else if (ignitionState == 2) {
      stateText = 'START';
      stateColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ignition Switch (Term 30/15/50)', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: isBatteryConnected ? _cycleIgnition : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: stateColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Turn Key: $stateText'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _statusRow('System Voltage', isBatteryConnected ? (isEngineRunning ? '7.2V (Charging)' : '6.1V') : '0.0V'),
          _statusRow('Engine', isEngineRunning ? 'Running' : (ignitionState == 2 ? 'Cranking...' : 'Stopped')),
          _statusRow('Generator', isEngineRunning ? 'Generating' : 'Inactive'),
          _statusRow('Headlights', isLightSwitchOn && isBatteryConnected ? 'ON' : 'OFF'),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
