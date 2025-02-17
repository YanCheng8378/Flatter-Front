import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class DataDisplayPage extends StatefulWidget {
  const DataDisplayPage({Key? key}) : super(key: key);

  @override
  State<DataDisplayPage> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<DataDisplayPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  String receivedData = "No data yet";

  @override
  void initState() {
    super.initState();
    _bluetoothService.dataStream.listen((data) {
      setState(() {
        receivedData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Received Data")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                receivedData,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
