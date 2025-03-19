// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import '../services/bluetooth_service.dart' as myService;
//
// class BluetoothDevicesPage extends StatefulWidget {
//   const BluetoothDevicesPage({Key? key}) : super(key: key);
//
//   @override
//   State<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
// }
//
// class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
//   final myService.BluetoothService _bluetoothService = myService.BluetoothService();
//   List<BluetoothDevice> bondedDevices = [];
//   List<ScanResult> scanResults = [];
//   bool isScanning = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _bluetoothService.initialize();
//
//     _bluetoothService.bondedDevicesStream.listen((devices) {
//       setState(() {
//         bondedDevices = devices;
//       });
//     });
//
//     _bluetoothService.scanResultsStream.listen((results) {
//       setState(() {
//         scanResults = results;
//       });
//     });
//   }
//
//   void _startScan() {
//     setState(() {
//       isScanning = true;
//     });
//     _bluetoothService.startScan().then((_) {
//       setState(() {
//         isScanning = false;
//       });
//     });
//   }
//
//   void _connectToDevice(BluetoothDevice device) {
//     _bluetoothService.connectToDevice(device);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Available Bluetooth Devices")),
//       body: Column(
//         children: [
//           // Bonded Devices 区域
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Text(
//               "Bonded Devices",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: bondedDevices.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(bondedDevices[index].platformName),
//                   subtitle: Text(bondedDevices[index].remoteId.toString()),
//                   trailing: ElevatedButton(
//                     onPressed: () {
//                       _connectToDevice(bondedDevices[index]);
//                     },
//                     child: const Text("Connect"),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const Divider(),
//
//           // Scanned Devices 区域
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Text(
//               "Scanned Devices",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: scanResults.length,
//               itemBuilder: (context, index) {
//                 final device = scanResults[index].device;
//                 return ListTile(
//                   title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown"),
//                   subtitle: Text(device.remoteId.toString()),
//                   trailing: ElevatedButton(
//                     onPressed: () {
//                       _connectToDevice(device);
//                     },
//                     child: const Text("Connect"),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _startScan,
//         child: Icon(isScanning ? Icons.stop : Icons.search),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _bluetoothService.dispose();
//     super.dispose();
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import '../services/bluetooth_service.dart' as myService;

class BluetoothDevicesPage extends StatefulWidget {
  const BluetoothDevicesPage({Key? key}) : super(key: key);

  @override
  State<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  final myService.BluetoothService _bluetoothService = myService.BluetoothService();

  // The default target device name you want to connect to
  static const String _targetDeviceName = "Nano33BLE_Predictor";

  fb.BluetoothDevice? _selectedDevice;  // The bonded device if found
  bool _isConnecting = false;
  myService.ConnectionState _connectionState = myService.ConnectionState.disconnected;

  late StreamSubscription<myService.ConnectionState> _connectionSubscription;
  StreamSubscription<List<fb.BluetoothDevice>>? _bondedSubscription; // Listen to bonded devices

  @override
  void initState() {
    super.initState();

    // Initialize the Bluetooth service
    _bluetoothService.initialize();

    // Listen to the connection state
    _connectionSubscription = _bluetoothService.connectionStateStream.listen((state) {
      setState(() {
        _connectionState = state;
      });
    });

    // Listen to the bonded device list; once received, check if it contains the target device
    // Note: _bluetoothService.bondedDevicesStream needs to be properly implemented in your BluetoothService
    _bondedSubscription = _bluetoothService.bondedDevicesStream.listen((bondedDevices) {
      for (final device in bondedDevices) {
        if (device.platformName == _targetDeviceName) {
          setState(() {
            _selectedDevice = device;
          });
          break; // Exit the loop once the device is found
        }
      }
    });
  }

  /// Connect to the selected device
  void _connectToDevice() async {
    if (_selectedDevice == null) {
      // If we didn't find the target device in the bonded list, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nano33BLE_Predictor not found among bonded devices")),
      );
      return;
    }

    setState(() => _isConnecting = true);
    try {
      // Use the connection logic encapsulated in the service
      await _bluetoothService.connectToDevice(_selectedDevice!);

      // Wait up to 5 seconds, until the characteristic is successfully subscribed
      bool isSubscribed = false;
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        isSubscribed = _bluetoothService.isSubscribed;
        return !isSubscribed; // Once isSubscribed = true, exit the loop
      }).timeout(const Duration(seconds: 5));

      if (isSubscribed) {
        Navigator.pushNamedAndRemoveUntil(context, "/root_app", (route) => false);
      } else {
        throw Exception("Failed to subscribe to the characteristic, please check the device service");
      }
    } on TimeoutException {
      showDialog(
        context: context,
        builder: (ctx) => const AlertDialog(
          title: Text("Connection Timeout"),
          content: Text("Could not subscribe to the data channel within the specified time"),
        ),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectionState == myService.ConnectionState.connected;
    final isConnecting = _connectionState == myService.ConnectionState.connecting;

    // Display different text based on connection state
    String statusText;
    if (isConnected) {
      statusText = "Connected to Mini HAR";
    } else if (isConnecting) {
      statusText = "Connecting...";
    } else {
      statusText = "Not connected with Mini HAR.";
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Bluetooth Connection"),
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: Colors.black),
      // ),
      appBar: null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 使用 Expanded 包裹一个 Column，让文本整体居中
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.green : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Make sure the device is powered on and paired in the system. Click the button below to connect.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // 按钮放在最下方
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // 自定义圆角弧度，比如 12
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (isConnecting || isConnected) ? null : _connectToDevice,
                  child: _isConnecting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel subscriptions to prevent memory leaks
    _connectionSubscription.cancel();
    _bondedSubscription?.cancel();
    super.dispose();
  }
}
