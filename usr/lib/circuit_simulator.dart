import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CircuitSimulator extends StatefulWidget {
  final bool isBatteryConnected;
  final int ignitionState; // 0: Off, 1: On, 2: Start
  final bool isLightSwitchOn;
  final bool isEngineRunning;

  const CircuitSimulator({
    super.key,
    required this.isBatteryConnected,
    required this.ignitionState,
    required this.isLightSwitchOn,
    required this.isEngineRunning,
  });

  @override
  State<CircuitSimulator> createState() => _CircuitSimulatorState();
}

class _CircuitSimulatorState extends State<CircuitSimulator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Center the schematic initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _transformationController.value = Matrix4.identity()
        ..translate(size.width / 4, size.height / 4)
        ..scale(0.8);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(1000),
        minScale: 0.1,
        maxScale: 4.0,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(2000, 2000),
              painter: SchematicPainter(
                animationValue: _animationController.value,
                isBatteryConnected: widget.isBatteryConnected,
                ignitionState: widget.ignitionState,
                isLightSwitchOn: widget.isLightSwitchOn,
                isEngineRunning: widget.isEngineRunning,
              ),
            );
          },
        ),
      ),
    );
  }
}

class SchematicPainter extends CustomPainter {
  final double animationValue;
  final bool isBatteryConnected;
  final int ignitionState;
  final bool isLightSwitchOn;
  final bool isEngineRunning;

  SchematicPainter({
    required this.animationValue,
    required this.isBatteryConnected,
    required this.ignitionState,
    required this.isLightSwitchOn,
    required this.isEngineRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define Nodes (Components)
    final nodes = {
      'Battery': _Node(const Offset(100, 400), '6V Battery', Colors.red.shade900),
      'Ground': _Node(const Offset(100, 500), 'Chassis Ground', Colors.grey.shade800),
      'Starter': _Node(const Offset(300, 550), 'Starter Motor\n(Term 30/50)', Colors.grey.shade700),
      'Regulator': _Node(const Offset(300, 250), 'Voltage Regulator', Colors.blueGrey),
      'Generator': _Node(const Offset(300, 100), 'Generator', Colors.blueGrey.shade700),
      'IgnitionSwitch': _Node(const Offset(500, 400), 'Ignition Switch\n(Term 30/15/50)', Colors.orange.shade800),
      'LightSwitch': _Node(const Offset(500, 600), 'Light Switch\n(Term 30/56)', Colors.blue.shade800),
      'FuseBox': _Node(const Offset(700, 600), 'Fuse Box', Colors.teal.shade700),
      'Coil': _Node(const Offset(700, 400), 'Ignition Coil\n(Term 15/1)', Colors.purple.shade800),
      'Distributor': _Node(const Offset(900, 400), 'Distributor', Colors.brown.shade700),
      'SparkPlugs': _Node(const Offset(1100, 400), 'Spark Plugs (1-4)', Colors.amber.shade800),
      'Headlights': _Node(const Offset(900, 550), 'Headlights', Colors.yellow.shade700),
      'Taillights': _Node(const Offset(900, 650), 'Taillights', Colors.red.shade600),
    };

    // Determine Circuit Logic (Electricity Flow)
    bool batteryPower = isBatteryConnected;
    bool term30Power = batteryPower; // Always hot if battery connected
    bool term15Power = term30Power && (ignitionState == 1 || ignitionState == 2); // Ignition ON or START
    bool term50Power = term30Power && ignitionState == 2; // START only
    bool lightsPower = term30Power && isLightSwitchOn;
    bool chargingPower = isEngineRunning; // Generator producing power
    bool sparkPower = term15Power && (isEngineRunning || ignitionState == 2);

    // Define Wires
    final wires = [
      // Ground
      _Wire('Battery', 'Ground', true, false, Colors.black, thickness: 6.0),
      
      // Main Power (Terminal 30) - Thick Red Wire
      _Wire('Battery', 'Starter', term30Power, term30Power, Colors.red, thickness: 6.0),
      _Wire('Starter', 'IgnitionSwitch', term30Power, term30Power, Colors.red),
      _Wire('Starter', 'LightSwitch', term30Power, term30Power, Colors.red),
      _Wire('Battery', 'Regulator', term30Power, chargingPower, Colors.red), // B+
      
      // Charging System
      _Wire('Regulator', 'Generator', chargingPower, chargingPower, Colors.green), // D+
      _Wire('Regulator', 'Generator', chargingPower, chargingPower, Colors.green.shade300, offset: const Offset(10, 10)), // DF
      
      // Ignition System (Terminal 15 & 50)
      _Wire('IgnitionSwitch', 'Starter', term50Power, term50Power, Colors.orange), // Term 50 (Cranking)
      _Wire('IgnitionSwitch', 'Coil', term15Power, term15Power, Colors.black), // Term 15 (Ignition ON)
      _Wire('Coil', 'Distributor', term15Power, sparkPower, Colors.green), // Term 1 (Points)
      _Wire('Distributor', 'SparkPlugs', sparkPower, sparkPower, Colors.blue, thickness: 4.0, isSpark: true), // High Tension
      
      // Lighting System
      _Wire('LightSwitch', 'FuseBox', lightsPower, lightsPower, Colors.grey.shade300),
      _Wire('FuseBox', 'Headlights', lightsPower, lightsPower, Colors.yellow),
      _Wire('FuseBox', 'Taillights', lightsPower, lightsPower, Colors.grey),
    ];

    // Draw Wires
    for (var wire in wires) {
      final start = nodes[wire.from]!.position;
      final end = nodes[wire.to]!.position;
      
      // Apply offset if multiple wires between same nodes
      final startPos = start + wire.offset;
      final endPos = end + wire.offset;

      _drawWire(canvas, startPos, endPos, wire, animationValue);
    }

    // Draw Nodes
    for (var node in nodes.values) {
      _drawNode(canvas, node);
    }
    
    // Draw Spark Effect if running
    if (sparkPower) {
      _drawSparkEffect(canvas, nodes['SparkPlugs']!.position);
    }
    
    // Draw Light Effect if lights on
    if (lightsPower) {
      _drawLightEffect(canvas, nodes['Headlights']!.position, Colors.yellow);
      _drawLightEffect(canvas, nodes['Taillights']!.position, Colors.red);
    }
  }

  void _drawWire(Canvas canvas, Offset start, Offset end, _Wire wire, double animValue) {
    final paint = Paint()
      ..color = wire.hasPower ? wire.color : Colors.grey.shade800
      ..strokeWidth = wire.thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw base wire
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Create orthogonal routing (Manhattan routing) for schematic look
    final midX = start.dx + (end.dx - start.dx) / 2;
    path.lineTo(midX, start.dy);
    path.lineTo(midX, end.dy);
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);

    // Draw flowing electricity animation
    if (wire.isFlowing) {
      final flowPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = wire.thickness * 0.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (wire.isSpark) {
        flowPaint.color = Colors.blueAccent;
        flowPaint.strokeWidth = wire.thickness * 1.5;
      }

      // Create dashed path for animation
      final dashPath = _createDashedPath(path, 15.0, 15.0, animValue * 30.0);
      canvas.drawPath(dashPath, flowPaint);
    }
  }

  Path _createDashedPath(Path source, double dashLength, double dashSpace, double phase) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = phase % (dashLength + dashSpace);
      if (distance > 0) {
        distance -= (dashLength + dashSpace);
      }
      while (distance < metric.length) {
        final double start = distance;
        final double end = distance + dashLength;
        if (end > 0) {
          dest.addPath(
            metric.extractPath(max(0, start), min(metric.length, end)),
            Offset.zero,
          );
        }
        distance += dashLength + dashSpace;
      }
    }
    return dest;
  }

  void _drawNode(Canvas canvas, _Node node) {
    final paint = Paint()
      ..color = node.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(center: node.position, width: 120, height: 60);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw Text
    final textSpan = TextSpan(
      text: node.label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 110, maxWidth: 110);
    textPainter.paint(
      canvas,
      Offset(node.position.dx - textPainter.width / 2, node.position.dy - textPainter.height / 2),
    );
  }

  void _drawSparkEffect(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.6 + 0.4 * sin(animationValue * pi * 20))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position + const Offset(70, 0), 15, paint);
    
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(position + const Offset(70, 0), 5, innerPaint);
  }
  
  void _drawLightEffect(Canvas canvas, Offset position, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
    canvas.drawCircle(position + const Offset(70, 0), 30, paint);
    
    final innerPaint = Paint()..color = color.withOpacity(0.8);
    canvas.drawCircle(position + const Offset(70, 0), 10, innerPaint);
  }

  @override
  bool shouldRepaint(covariant SchematicPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isBatteryConnected != isBatteryConnected ||
           oldDelegate.ignitionState != ignitionState ||
           oldDelegate.isLightSwitchOn != isLightSwitchOn ||
           oldDelegate.isEngineRunning != isEngineRunning;
  }
}

class _Node {
  final Offset position;
  final String label;
  final Color color;

  _Node(this.position, this.label, this.color);
}

class _Wire {
  final String from;
  final String to;
  final bool hasPower;
  final bool isFlowing;
  final Color color;
  final double thickness;
  final Offset offset;
  final bool isSpark;

  _Wire(
    this.from,
    this.to,
    this.hasPower,
    this.isFlowing,
    this.color, {
    this.thickness = 3.0,
    this.offset = Offset.zero,
    this.isSpark = false,
  });
}
