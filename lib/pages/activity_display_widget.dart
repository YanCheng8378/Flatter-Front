import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/bluetooth_service.dart';

class ActivityDisplayWidget extends StatefulWidget {
  final BluetoothService bluetoothService;
  const ActivityDisplayWidget({Key? key, required this.bluetoothService}) : super(key: key);

  @override
  _ActivityDisplayWidgetState createState() => _ActivityDisplayWidgetState();
}

class _ActivityDisplayWidgetState extends State<ActivityDisplayWidget> {
  String _activity = "No device connected";
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // 监听连接状态
    widget.bluetoothService.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
        if (!connected) _activity = "No device connected";
      });
    });

    // 监听预测数据流
    widget.bluetoothService.predictionDataStringStream.listen((dataStr) {
      final parsed = BluetoothService.parsePredictionData(utf8.encode(dataStr));
      if (parsed != _activity) {
        setState(() => _activity = parsed);
      }
    });
  }

  final Map<String, String> _activityGifMapping = {
    "Cycling": "assets/gifs/cycling.gif",
    "WalkDownstairs": "assets/gifs/stairsDown.gif",
    "Jogging": "assets/gifs/jogging.gif",
    "Lying": "assets/gifs/lying.gif",
    "Sitting": "assets/gifs/sitting.gif",
    "WalkUpstairs": "assets/gifs/stairsUp.gif",
    "Walking": "assets/gifs/walking.gif",
    "Unknown Activity": "assets/gifs/unknown.gif",
    "No device connected": "assets/gifs/signal.gif",
    "Loading...": "assets/gifs/813.gif",
    "Error": "assets/gifs/Error.gif",
  };

  String _mapPredictionToActivity(dynamic data) {
    // Check that the received data is a list of integers.
    if (data is List<int>) {
      // Ensure that the data length is at least 8 bytes.
      if (data.length >= 8) {
        final byteData = Uint8List.fromList(data).buffer.asByteData();
        // Read the 32-bit integer starting at index 4 (little-endian).
        int prediction = byteData.getInt32(4, Endian.little);
        // Mapping based on your provided dictionary:
        switch (prediction) {
          case 0:
            return "Cycling";
          case 1:
            return "WalkDownstairs";
          case 2:
            return "Jogging";
          case 3:
            return "Lying";
          case 4:
            return "Sitting";
          case 5:
            return "WalkUpstairs";
          case 6:
            return "Walking";
          default:
            return "Unknown Activity";
        }
      } else {
        return "loading...";
      }
    }
    return "Error";
  }

  @override
  Widget build(BuildContext context) {
    final gifPath = _activityGifMapping[_activity] ??
        _activityGifMapping["Unknown Activity"]!;
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          // 连接状态指示器
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CURRENT ACTIVITY",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _activity,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Image.asset(gifPath, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}