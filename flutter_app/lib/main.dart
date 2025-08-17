import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GreenhouseApp());
}

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greenhouse Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const GreenhouseDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GreenhouseDashboard extends StatefulWidget {
  const GreenhouseDashboard({super.key});

  @override
  State<GreenhouseDashboard> createState() => _GreenhouseDashboardState();
}

class _GreenhouseDashboardState extends State<GreenhouseDashboard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Data variables
  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _fanStatus = false;
  String _lastUpdate = 'Never';
  bool _isConnected = false;
  
  // AI Model variables
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool _isAIMode = true; // Toggle between AI and manual mode
  String _aiPrediction = 'Analyzing...';
  
  late StreamSubscription _climateSubscription;
  late StreamSubscription _fanSubscription;

  @override
  void initState() {
    super.initState();
    _loadAIModel();
    _setupFirebaseListeners();
  }

    // Load AI Model
  Future<void> _loadAIModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/grenhouse_model.tflite');
      setState(() {
        _isModelLoaded = true;
        _aiPrediction = 'Model Ready';
      });
      print('✅ AI Model loaded successfully');
    } catch (e) {
      setState(() {
        _isModelLoaded = false;
        _aiPrediction = 'Model Error';
      });
      print('❌ Failed to load AI model: $e');
    }
  }

  // Make AI Prediction
  Future<bool> _makeAIPrediction(double temperature, double humidity) async {
    if (!_isModelLoaded || _interpreter == null) {
      return false; // Default to OFF if model not loaded
    }

    try {
      // Normalize inputs (based on your training notebook MinMaxScaler)
      // Training data ranges: temp [20.9, 90.5], humidity [31.69, 100.0]
      // MinMaxScaler formula: (value - min) / (max - min)
      double normalizedTemp = (temperature - 20.9) / (90.5 - 20.9);
      double normalizedHumidity = (humidity - 31.69) / (100.0 - 31.69);

      // Prepare input
      var input = [
        [normalizedTemp, normalizedHumidity]
      ];

      // Prepare output
      var output = List.filled(1 * 1, 0).reshape([1, 1]);

      // Run inference
      _interpreter!.run(input, output);

      // Get prediction (sigmoid output, threshold at 0.5)
      double prediction = output[0][0];
      bool shouldTurnOn = prediction > 0.5;

      setState(() {
        _aiPrediction = shouldTurnOn 
          ? 'AI: Turn ON (${(prediction * 100).toStringAsFixed(1)}%)'
          : 'AI: Turn OFF (${((1 - prediction) * 100).toStringAsFixed(1)}%)';
      });

      print('🧠 AI Prediction: $prediction, Decision: ${shouldTurnOn ? "ON" : "OFF"}');
      return shouldTurnOn;

    } catch (e) {
      print('❌ AI Prediction error: $e');
      setState(() {
        _aiPrediction = 'Prediction Error';
      });
      return false;
    }
  }

  void _setupFirebaseListeners() {
    // Listen to climate data
    _climateSubscription = _database.child('climate_data').onValue.listen((event) async {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        double newTemp = (data['temperature_c'] ?? 0.0).toDouble();
        double newHumidity = (data['humidity_percent'] ?? 0.0).toDouble();
        
        setState(() {
          _temperature = newTemp;
          _humidity = newHumidity;
          _lastUpdate = data['timestamp'] ?? 'Unknown';
          _isConnected = true;
        });

        // Make AI prediction if in AI mode
        if (_isAIMode && _isModelLoaded) {
          bool aiDecision = await _makeAIPrediction(newTemp, newHumidity);
          
          // Send AI decision to Firebase (only if different from current status)
          if (aiDecision != _fanStatus) {
            await _database.child('fan_on').set(aiDecision);
            print('🤖 AI Decision sent to Firebase: ${aiDecision ? "ON" : "OFF"}');
          }
        }
      }
    });

    // Listen to fan status
    _fanSubscription = _database.child('current_fan_status').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _fanStatus = event.snapshot.value as bool? ?? false;
        });
      }
    });
  }

  void _toggleFan() async {
    if (_isAIMode) {
      // In AI mode, toggle between AI and manual
      setState(() {
        _isAIMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched to Manual Mode'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Manual fan control
    try {
      await _database.child('fan_on').set(!_fanStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fan ${!_fanStatus ? 'ON' : 'OFF'} command sent'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleAIMode() {
    setState(() {
      _isAIMode = !_isAIMode;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAIMode ? 'AI Mode Enabled' : 'Manual Mode Enabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _climateSubscription.cancel();
    _fanSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '🌱 Greenhouse Fan Controller',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Weather Info Section
            _buildWeatherCard(),
            const SizedBox(height: 20),
            
            // Gauges Section
            Row(
              children: [
                Expanded(child: _buildTemperatureGauge()),
                const SizedBox(width: 16),
                Expanded(child: _buildHumidityGauge()),
              ],
            ),
            const SizedBox(height: 30),
            
            // Fan Control Section
            _buildFanControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🌤️ Weather Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isModelLoaded ? Colors.purple : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isModelLoaded ? 'AI' : 'NO AI',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isConnected ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Last Updated: $_lastUpdate',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (_isModelLoaded) ...[
            const SizedBox(height: 8),
            Text(
              _aiPrediction,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemperatureGauge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🌡️ Temperature',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: CircularGaugePainter(
                value: _temperature,
                maxValue: 50,
                color: Colors.orange,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _temperature.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityGauge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '💧 Humidity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: CircularGaugePainter(
                value: _humidity,
                maxValue: 100,
                color: Colors.blue,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _humidity.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '%',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanControl() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🌀 Fan Control',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _isAIMode,
                onChanged: _isModelLoaded ? (value) => _toggleAIMode() : null,
                activeTrackColor: Colors.purple,
              ),
            ],
          ),
          Text(
            _isAIMode ? '🤖 AI Mode' : '🎮 Manual Mode',
            style: TextStyle(
              color: _isAIMode ? Colors.purple : Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          if (_isAIMode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    '🧠 AI is controlling the fan based on your trained model',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Decision: ${_fanStatus ? "🟢 ON" : "🔴 OFF"}',
                    style: TextStyle(
                      color: _fanStatus ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _toggleFan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _fanStatus ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_fanStatus ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    _fanStatus ? 'TURN OFF' : 'TURN ON',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fan is currently ${_fanStatus ? 'ON' : 'OFF'}',
              style: TextStyle(
                color: _fanStatus ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CircularGaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  CircularGaugePainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = (value / maxValue) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}