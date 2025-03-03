import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/bluetooth_service.dart';

class DataChartPage extends StatefulWidget {
  const DataChartPage({Key? key}) : super(key: key);

  @override
  _DataChartPageState createState() => _DataChartPageState();
}

class _DataChartPageState extends State<DataChartPage> {
  // --- Chart Data Lists for Each Sensor Type (each with X, Y, Z) ---
  // Acceleration
  final List<FlSpot> _chartDataAccX = [];
  final List<FlSpot> _chartDataAccY = [];
  final List<FlSpot> _chartDataAccZ = [];
  // Gravity
  final List<FlSpot> _chartDataGravityX = [];
  final List<FlSpot> _chartDataGravityY = [];
  final List<FlSpot> _chartDataGravityZ = [];
  // Linear Acceleration
  final List<FlSpot> _chartDataLinearX = [];
  final List<FlSpot> _chartDataLinearY = [];
  final List<FlSpot> _chartDataLinearZ = [];
  // Gyroscope
  final List<FlSpot> _chartDataGyroX = [];
  final List<FlSpot> _chartDataGyroY = [];
  final List<FlSpot> _chartDataGyroZ = [];

  // --- Smoothing Buffers (for moving average) ---
  // Acceleration buffers
  final List<double> _bufferAccX = [];
  final List<double> _bufferAccY = [];
  final List<double> _bufferAccZ = [];
  // Gravity buffers
  final List<double> _bufferGravityX = [];
  final List<double> _bufferGravityY = [];
  final List<double> _bufferGravityZ = [];
  // Linear acceleration buffers
  final List<double> _bufferLinearX = [];
  final List<double> _bufferLinearY = [];
  final List<double> _bufferLinearZ = [];
  // Gyroscope buffers
  final List<double> _bufferGyroX = [];
  final List<double> _bufferGyroY = [];
  final List<double> _bufferGyroZ = [];

  static const int _windowSize = 10;

  // --- Latest smoothed values (for each data type and axis) ---
  double _latestAccX = 0, _latestAccY = 0, _latestAccZ = 0;
  double _latestGravityX = 0, _latestGravityY = 0, _latestGravityZ = 0;
  double _latestLinearX = 0, _latestLinearY = 0, _latestLinearZ = 0;
  double _latestGyroX = 0, _latestGyroY = 0, _latestGyroZ = 0;
  double _latestElapsedTime = 0; // in seconds

  late StreamSubscription<List<int>> _sensorSubscription;
  Timer? _updateTimer;
  late int _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;

    // Subscribe to BLE sensor data stream.
    _sensorSubscription = BluetoothService().sensorDataStream.listen((data) {
      // Expecting a packet of 52 bytes: 4-byte index + 12 floats (4 bytes each).
      if (data.length >= 52) {
        final byteData = ByteData.sublistView(Uint8List.fromList(data));

        // Read sensor values (float32, little-endian)
        double accX = byteData.getFloat32(4, Endian.little);
        double accY = byteData.getFloat32(8, Endian.little);
        double accZ = byteData.getFloat32(12, Endian.little);

        double gravX = byteData.getFloat32(16, Endian.little);
        double gravY = byteData.getFloat32(20, Endian.little);
        double gravZ = byteData.getFloat32(24, Endian.little);

        double linX = byteData.getFloat32(28, Endian.little);
        double linY = byteData.getFloat32(32, Endian.little);
        double linZ = byteData.getFloat32(36, Endian.little);

        double gyroX = byteData.getFloat32(40, Endian.little);
        double gyroY = byteData.getFloat32(44, Endian.little);
        double gyroZ = byteData.getFloat32(48, Endian.little);

        // Calculate elapsed time in seconds.
        int now = DateTime.now().millisecondsSinceEpoch;
        double elapsedSeconds = (now - _startTime) / 1000.0;
        _latestElapsedTime = elapsedSeconds;

        // --- Update smoothing buffers and compute moving averages ---

        // Acceleration smoothing.
        _bufferAccX.add(accX);
        if (_bufferAccX.length > _windowSize) _bufferAccX.removeAt(0);
        _bufferAccY.add(accY);
        if (_bufferAccY.length > _windowSize) _bufferAccY.removeAt(0);
        _bufferAccZ.add(accZ);
        if (_bufferAccZ.length > _windowSize) _bufferAccZ.removeAt(0);
        _latestAccX = _bufferAccX.reduce((a, b) => a + b) / _bufferAccX.length;
        _latestAccY = _bufferAccY.reduce((a, b) => a + b) / _bufferAccY.length;
        _latestAccZ = _bufferAccZ.reduce((a, b) => a + b) / _bufferAccZ.length;

        // Gravity smoothing.
        _bufferGravityX.add(gravX);
        if (_bufferGravityX.length > _windowSize) _bufferGravityX.removeAt(0);
        _bufferGravityY.add(gravY);
        if (_bufferGravityY.length > _windowSize) _bufferGravityY.removeAt(0);
        _bufferGravityZ.add(gravZ);
        if (_bufferGravityZ.length > _windowSize) _bufferGravityZ.removeAt(0);
        _latestGravityX = _bufferGravityX.reduce((a, b) => a + b) / _bufferGravityX.length;
        _latestGravityY = _bufferGravityY.reduce((a, b) => a + b) / _bufferGravityY.length;
        _latestGravityZ = _bufferGravityZ.reduce((a, b) => a + b) / _bufferGravityZ.length;

        // Linear acceleration smoothing.
        _bufferLinearX.add(linX);
        if (_bufferLinearX.length > _windowSize) _bufferLinearX.removeAt(0);
        _bufferLinearY.add(linY);
        if (_bufferLinearY.length > _windowSize) _bufferLinearY.removeAt(0);
        _bufferLinearZ.add(linZ);
        if (_bufferLinearZ.length > _windowSize) _bufferLinearZ.removeAt(0);
        _latestLinearX = _bufferLinearX.reduce((a, b) => a + b) / _bufferLinearX.length;
        _latestLinearY = _bufferLinearY.reduce((a, b) => a + b) / _bufferLinearY.length;
        _latestLinearZ = _bufferLinearZ.reduce((a, b) => a + b) / _bufferLinearZ.length;

        // Gyroscope smoothing.
        _bufferGyroX.add(gyroX);
        if (_bufferGyroX.length > _windowSize) _bufferGyroX.removeAt(0);
        _bufferGyroY.add(gyroY);
        if (_bufferGyroY.length > _windowSize) _bufferGyroY.removeAt(0);
        _bufferGyroZ.add(gyroZ);
        if (_bufferGyroZ.length > _windowSize) _bufferGyroZ.removeAt(0);
        _latestGyroX = _bufferGyroX.reduce((a, b) => a + b) / _bufferGyroX.length;
        _latestGyroY = _bufferGyroY.reduce((a, b) => a + b) / _bufferGyroY.length;
        _latestGyroZ = _bufferGyroZ.reduce((a, b) => a + b) / _bufferGyroZ.length;
      }
    });

    // Update UI periodically (every 50ms) to add the latest smoothed values.
    _updateTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        // Add the current data (using elapsed time as x) to each chart list.
        _chartDataAccX.add(FlSpot(_latestElapsedTime, _latestAccX));
        _chartDataAccY.add(FlSpot(_latestElapsedTime, _latestAccY));
        _chartDataAccZ.add(FlSpot(_latestElapsedTime, _latestAccZ));

        _chartDataGravityX.add(FlSpot(_latestElapsedTime, _latestGravityX));
        _chartDataGravityY.add(FlSpot(_latestElapsedTime, _latestGravityY));
        _chartDataGravityZ.add(FlSpot(_latestElapsedTime, _latestGravityZ));

        _chartDataLinearX.add(FlSpot(_latestElapsedTime, _latestLinearX));
        _chartDataLinearY.add(FlSpot(_latestElapsedTime, _latestLinearY));
        _chartDataLinearZ.add(FlSpot(_latestElapsedTime, _latestLinearZ));

        _chartDataGyroX.add(FlSpot(_latestElapsedTime, _latestGyroX));
        _chartDataGyroY.add(FlSpot(_latestElapsedTime, _latestGyroY));
        _chartDataGyroZ.add(FlSpot(_latestElapsedTime, _latestGyroZ));

        // Optionally, limit each list to the latest 100 data points.
        if (_chartDataAccX.length > 100) {
          _chartDataAccX.removeAt(0);
          _chartDataAccY.removeAt(0);
          _chartDataAccZ.removeAt(0);
          _chartDataGravityX.removeAt(0);
          _chartDataGravityY.removeAt(0);
          _chartDataGravityZ.removeAt(0);
          _chartDataLinearX.removeAt(0);
          _chartDataLinearY.removeAt(0);
          _chartDataLinearZ.removeAt(0);
          _chartDataGyroX.removeAt(0);
          _chartDataGyroY.removeAt(0);
          _chartDataGyroZ.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  Widget _buildChartCard(String chartTitle, List<FlSpot> dataX, List<FlSpot> dataY, List<FlSpot> dataZ,
      {double minY = -20, double maxY = 20}) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              chartTitle,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 100,
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[800]!,
                        strokeWidth: 0.1,
                      );
                    },
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[700]!,
                        strokeWidth: 0.1,
                      );
                    },
                  ),
                  minY: minY,
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          // Show time markers every second
                          if (value % 1 != 0) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${value.toInt()}s',
                              style: TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: _latestElapsedTime > 10 ? _latestElapsedTime - 5 : 0,
                  maxX: _latestElapsedTime > 0 ? _latestElapsedTime : 1,
                  lineBarsData: [
                    // X-axis data (red)
                    LineChartBarData(
                      spots: dataX,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      gradient: LinearGradient(
                        colors: [Colors.redAccent.withOpacity(0.7), Colors.red],
                      ),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Y-axis data (green)
                    LineChartBarData(
                      spots: dataY,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      gradient: LinearGradient(
                        colors: [Colors.greenAccent.withOpacity(0.7), Colors.green],
                      ),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Z-axis data (blue)
                    LineChartBarData(
                      spots: dataZ,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent.withOpacity(0.7), Colors.blue],
                      ),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBarWithLegend() {
    return AppBar(
      title: Text("Sensor Data"),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Row(
          children: [
            _buildLegendItem("X", Colors.red),
            SizedBox(width: 12),
            _buildLegendItem("Y", Colors.green),
            SizedBox(width: 12),
            _buildLegendItem("Z", Colors.blue),
            SizedBox(width: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String axis, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Text(
          axis,
          style: TextStyle(color: Colors.black, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBarWithLegend(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildChartCard("Acceleration", _chartDataAccX, _chartDataAccY, _chartDataAccZ, minY: -30, maxY: 30),
            _buildChartCard("Gravity", _chartDataGravityX, _chartDataGravityY, _chartDataGravityZ, minY: -30, maxY: 30),
            _buildChartCard("Linear Acceleration", _chartDataLinearX, _chartDataLinearY, _chartDataLinearZ, minY: -20, maxY: 20),
            _buildChartCard("Gyroscope", _chartDataGyroX, _chartDataGyroY, _chartDataGyroZ, minY: -5, maxY: 5),
          ],
        ),
      ),
    );
  }
}