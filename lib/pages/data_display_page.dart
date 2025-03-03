import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/bluetooth_service.dart';

class DataDisplayPage extends StatefulWidget {
  const DataDisplayPage({Key? key}) : super(key: key);

  @override
  State<DataDisplayPage> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<DataDisplayPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  String activityType = "No device connected";

  // Map each activity to its corresponding GIF asset path.
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

  @override
  void initState() {
    super.initState();
    // Listen to the stream of data coming from the BLE service.
    _bluetoothService.predictionDataStream.listen((data) {
      String newActivity = _mapPredictionToActivity(data);
      // Update the UI only if the activity has changed.
      if (newActivity != activityType) {
        setState(() {
          activityType = newActivity;
        });
      }
    });
  }

  /// Extracts the prediction from the received data (assumed to be an 8-byte array)
  /// and maps it to a human-readable activity based on your provided mapping.
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
    // Get the asset path for the current activity.
    String gifAsset =
        _activityGifMapping[activityType] ?? _activityGifMapping["Unknown Activity"]!;
    return Scaffold(
      appBar: AppBar(title: const Text("Activity Detector")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                activityType,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                height: 300, // Adjust height as needed
                width: 300,  // Adjust width as needed
                decoration: const BoxDecoration(
                  color: Colors.transparent, // Ensure container background is transparent
                ),
                child: Image.asset(
                  gifAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}