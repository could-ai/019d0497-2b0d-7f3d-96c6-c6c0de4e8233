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
      title: '1960 VW Beetle Wiring Simulator (12V Conversion)',
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
  int turnSignalState = 0; // 0: Off, 1: Left, 2: Right
  bool isHazardOn = false;
  bool isParkingLightsOn = false;
  bool isDomeLightOn = false;

  void _toggleBattery() {
    setState(() {
      isBatteryConnected = !isBatteryConnected;
      if (!isBatteryConnected) {
        ignitionState = 0;
        isLightSwitchOn = false;
        isEngineRunning = false;
        turnSignalState = 0;
        isHazardOn = false;
        isParkingLightsOn = false;
        isDomeLightOn = false;
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

  void _turnKeyOff() {
    if (!isBatteryConnected) return;
    setState(() {
      ignitionState = 0;
      isEngineRunning = false;
    });
  }

  void _toggleLights() {
    if (!isBatteryConnected) return;
    setState(() {
      isLightSwitchOn = !isLightSwitchOn;
    });
  }

  void _toggleParkingLights() {
    if (!isBatteryConnected) return;
    setState(() {
      isParkingLightsOn = !isParkingLightsOn;
    });
  }

  void _toggleDomeLight() {
    if (!isBatteryConnected) return;
    setState(() {
      isDomeLightOn = !isDomeLightOn;
    });
  }

  void _setTurnSignal(int state) {
    if (!isBatteryConnected) return;
    setState(() {
      turnSignalState = state;
      if (state != 0) isHazardOn = false; // Disable hazard when setting turn signals
    });
  }

  void _toggleHazard() {
    if (!isBatteryConnected) return;
    setState(() {
      isHazardOn = !isHazardOn;
      if (isHazardOn) turnSignalState = 0; // Disable turn signals when hazard on
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1960 VW Beetle Wiring Simulator (12V Conversion)'),
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
                const Divider(),
                _buildSwitch(
                  'Parking Lights',
                  isParkingLightsOn,
                  _toggleParkingLights,
                  activeColor: Colors.amber,
                ),
                const Divider(),
                _buildSwitch(
                  'Dome Light',
                  isDomeLightOn,
                  _toggleDomeLight,
                  activeColor: Colors.white,
                ),
                const Divider(),
                _buildTurnSignalControl(),
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
              turnSignalState: turnSignalState,
              isHazardOn: isHazardOn,
              isParkingLightsOn: isParkingLightsOn,
              isDomeLightOn: isDomeLightOn,
              onComponentTap: _showComponentDetails,
            ),
          ),
        ],
      ),
    );
  }

  void _showComponentDetails(String componentName) {
    if (componentName == 'FuseBox') {
      _showFuseBoxDetails();
      return;
    }
    String details = '';
    switch (componentName) {
      case 'Battery':
        details = '''12V Lead-Acid Battery (Converted from 6V)

- Provides 12V DC power to the entire system.
- Connected to chassis ground.
- When engine runs, charges via alternator (upgraded for 1600cc engine).
- Voltage: ${isBatteryConnected ? (isEngineRunning ? '14.2V (Charging)' : '12.6V') : '0.0V'}'';
        break;
      case 'Ground':
        details = '''Chassis Ground

- Common return path for all electrical circuits.
- Connected to vehicle frame/body.
- Ensures safe current flow back to battery negative terminal.'';
        break;
      case 'Starter':
        details = '''Starter Motor (12V Upgraded)

- High-current motor cranks the 1600cc engine.
- Term 30: Always hot (12V from battery).
- Term 50: Only hot during START (solenoid engages).
- Draws ~200A during cranking.'';
        break;
      case 'Regulator':
        details = '''Voltage Regulator

- Controls alternator output to prevent overcharging.
- Maintains ~14.2V charging voltage.
- Upgraded for 12V system and 1600cc engine load.'';
        break;
      case 'Generator':
        details = '''Alternator (Upgraded 12V/55A)

- Replaces original generator for 12V conversion.
- Produces AC, converts to DC via rectifier.
- D+ (Sense): Tells regulator when to charge.
- DF (Field): Excitation current from regulator.
- Output: 55A at 1600cc idle speed.'';
        break;
      case 'IgnitionSwitch':
        details = '''Ignition Switch

- 3-Position: OFF/ON/START.
- Term 30: Always hot (12V from battery).
- Term 15: Hot when ON (powers accessories).
- Term 50: Hot when START (cranks engine).'';
        break;
      case 'LightSwitch':
        details = '''Light Switch

- Controls headlights and taillights.
- Term 30: Always hot.
- Term 56: Hot when switch ON (12V to lights).'';
        break;
      case 'FuseBox':
        details = '''Fuse Box

- Protects circuits from overload.
- Contains fuses for lights, ignition, etc.
- 12V input from light switch, distributed to bulbs.'';
        break;
      case 'Coil':
        details = '''Ignition Coil (12V Upgraded)

- Steps up 12V to ~25,000V for spark plugs.
- Term 15: 12V when ignition ON.
- Term 1: Grounded by points in distributor.
- Dual-port coil for improved 1600cc performance.'';
        break;
      case 'Distributor':
        details = '''Distributor

- Distributes high-voltage to spark plugs.
- Contains points (breaker) and rotor.
- Timing advances with engine speed.
- 4-cylinder for 1600cc engine.'';
        break;
      case 'SparkPlugs':
        details = '''Spark Plugs (4 Cylinders)

- Ignite air-fuel mixture in 1600cc engine.
- Receive ~25kV from distributor.
- Gap: 0.025" for optimal performance.
- Sparks when points open (Term 1 grounded).'';
        break;
      case 'Headlights':
        details = '''Headlights

- Dual 12V/55W bulbs (high/low beam).
- Powered via fuse box when lights ON.
- Draw ~5A each at 12V.'';
        break;
      case 'Taillights':
        details = '''Taillights

- Combined brake/tail lights.
- 12V bulbs, powered same as headlights.
- Also include license plate light.'';
        break;
      case 'ParkingLights':
        details = '''Parking Lights

- Amber 12V bulbs on front fenders.
- Separate from headlights, can be on independently.
- Powered directly from light switch.
- Draw ~2A total at 12V.'';
        break;
      case 'DomeLight':
        details = '''Interior Dome Light

- 12V bulb in headliner.
- Typically door-activated, but here manual switch.
- Powers from ignition accessory circuit.
- Provides cabin illumination.'';
        break;
      case 'Radio':
        details = '''Sapphire I Radio

- Vintage AM radio with integrated speaker.
- 12V powered from ignition accessory.
- Grounded to chassis.
- Plays through built-in speaker.'';
        break;
      case 'Speaker':
        details = '''Radio Speaker

- 4-ohm speaker integrated with Sapphire I radio.
- Receives audio signal from radio.
- Grounded to chassis.
- Provides sound output.'';
        break;
      case 'TurnSignalRelay':
        details = '''Turn Signal Flasher Relay

- Thermal flasher interrupts current.
- Flashes ~1.5 times/second.
- Powers left/right turn signals or hazard lights.
- Grounds through switch to complete circuit.'';
        break;
      case 'TurnSignalSwitch':
        details = '''Turn Signal Switch

- 3-Position: Left/Off/Right.
- Routes 12V to appropriate relay terminals.
- Also activates dash indicator lights.'';
        break;
      case 'LeftTurnSignals':
        details = '''Left Turn Signals

- Amber 12V bulbs in front/rear.
- Flash via relay when switch set to LEFT.
- Also active during hazard mode.'';
        break;
      case 'RightTurnSignals':
        details = '''Right Turn Signals

- Amber 12V bulbs in front/rear.
- Flash via relay when switch set to RIGHT.
- Also active during hazard mode.'';
        break;
      default:
        details = 'Component details not available.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(componentName),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFuseBoxDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fuse Box Details'),
        content: SizedBox(
          width: 400,
          height: 600,
          child: Column(
            children: [
              const Text('1960 VW Beetle Fuse Layout (12V Conversion)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2,
                  children: [
                    _fuseItem('Fuse 1', 'Headlights (Left)', isLightSwitchOn && isBatteryConnected),
                    _fuseItem('Fuse 2', 'Headlights (Right)', isLightSwitchOn && isBatteryConnected),
                    _fuseItem('Fuse 3', 'Taillights', isLightSwitchOn && isBatteryConnected),
                    _fuseItem('Fuse 4', 'Parking Lights', isParkingLightsOn && isBatteryConnected),
                    _fuseItem('Fuse 5', 'Turn Signals', (turnSignalState != 0 || isHazardOn) && isBatteryConnected),
                    _fuseItem('Fuse 6', 'Ignition Coil', (ignitionState == 1 || ignitionState == 2) && isBatteryConnected),
                    _fuseItem('Fuse 7', 'Radio/Accessories', (ignitionState == 1 || ignitionState == 2) && isBatteryConnected),
                    _fuseItem('Fuse 8', 'Dome Light', isDomeLightOn && isBatteryConnected),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _fuseItem(String fuseName, String description, bool isPowered) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isPowered ? Colors.green.shade900 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white70),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(fuseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(description, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
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
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isBatteryConnected && ignitionState != 0 ? _turnKeyOff : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Turn Key Off'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnSignalControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Turn Signal Switch', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _setTurnSignal(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: turnSignalState == 1 ? Colors.orange : Colors.grey,
                ),
                child: const Text('Left'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _setTurnSignal(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: turnSignalState == 0 && !isHazardOn ? Colors.green : Colors.grey,
                ),
                child: const Text('Off'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _setTurnSignal(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: turnSignalState == 2 ? Colors.orange : Colors.grey,
                ),
                child: const Text('Right'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _toggleHazard,
            style: ElevatedButton.styleFrom(
              backgroundColor: isHazardOn ? Colors.red : Colors.grey,
            ),
            child: const Text('Hazard'),
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
          _statusRow('System Voltage', isBatteryConnected ? (isEngineRunning ? '14.2V (Charging)' : '12.6V') : '0.0V'),
          _statusRow('Engine', isEngineRunning ? 'Running (1600cc Dual Port)' : (ignitionState == 2 ? 'Cranking...' : 'Stopped')),
          _statusRow('Generator', isEngineRunning ? 'Generating (55A)' : 'Inactive'),
          _statusRow('Headlights', isLightSwitchOn && isBatteryConnected ? 'ON' : 'OFF'),
          _statusRow('Parking Lights', isParkingLightsOn && isBatteryConnected ? 'ON' : 'OFF'),
          _statusRow('Dome Light', isDomeLightOn && isBatteryConnected ? 'ON' : 'OFF'),
          _statusRow('Turn Signals', _getTurnSignalStatus()),
        ],
      ),
    );
  }

  String _getTurnSignalStatus() {
    if (!isBatteryConnected) return 'OFF';
    if (isHazardOn) return 'Hazard Flashing';
    switch (turnSignalState) {
      case 1: return 'Left Flashing';
      case 2: return 'Right Flashing';
      default: return 'OFF';
    }
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
