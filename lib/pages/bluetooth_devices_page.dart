import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart' as myService;

class BluetoothDevicesPage extends StatefulWidget {
  const BluetoothDevicesPage({Key? key}) : super(key: key);

  @override
  State<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  final myService.BluetoothService _bluetoothService = myService.BluetoothService();
  List<BluetoothDevice> bondedDevices = [];
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _bluetoothService.initialize();

    _bluetoothService.bondedDevicesStream.listen((devices) {
      setState(() {
        bondedDevices = devices;
      });
    });

    _bluetoothService.scanResultsStream.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  void _startScan() {
    setState(() {
      isScanning = true;
    });
    _bluetoothService.startScan().then((_) {
      setState(() {
        isScanning = false;
      });
    });
  }

  void _connectToDevice(BluetoothDevice device) {
    _bluetoothService.connectToDevice(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Bluetooth Devices")),
      body: Column(
        children: [
          // Bonded Devices 区域
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Bonded Devices",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bondedDevices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(bondedDevices[index].platformName),
                  subtitle: Text(bondedDevices[index].remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _connectToDevice(bondedDevices[index]);
                    },
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),
          const Divider(),

          // Scanned Devices 区域
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Scanned Devices",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final device = scanResults[index].device;
                return ListTile(
                  title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown"),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _connectToDevice(device);
                    },
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        child: Icon(isScanning ? Icons.stop : Icons.search),
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}
