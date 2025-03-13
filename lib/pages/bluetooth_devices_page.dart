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

  // 你想要默认连接的目标设备名称
  static const String _targetDeviceName = "Nano33BLE_Predictor";

  fb.BluetoothDevice? _selectedDevice;  // 找到的已绑定设备
  bool _isConnecting = false;
  myService.ConnectionState _connectionState = myService.ConnectionState.disconnected;

  late StreamSubscription<myService.ConnectionState> _connectionSubscription;
  StreamSubscription<List<fb.BluetoothDevice>>? _bondedSubscription; // 监听已绑定设备

  @override
  void initState() {
    super.initState();

    // 初始化蓝牙服务
    _bluetoothService.initialize();

    // 监听连接状态
    _connectionSubscription = _bluetoothService.connectionStateStream.listen((state) {
      setState(() {
        _connectionState = state;
      });
    });

    // 监听已绑定设备列表，一旦获取到列表，就检查是否包含目标设备
    // 注意：_bluetoothService.bondedDevicesStream 需要你在 BluetoothService 中有相应的实现
    _bondedSubscription = _bluetoothService.bondedDevicesStream.listen((bondedDevices) {
      // 尝试在已绑定设备中找到目标设备
      for (final device in bondedDevices) {
        if (device.platformName == _targetDeviceName) {
          setState(() {
            _selectedDevice = device;
          });
          break; // 找到后就退出循环
        }
      }
    });
  }

  /// 连接到选定设备
  void _connectToDevice() async {
    if (_selectedDevice == null) {
      // 如果在已绑定设备里没找到目标设备，就提示一下
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已绑定设备中未发现 Nano33BLE_Predictor")),
      );
      return;
    }

    setState(() => _isConnecting = true);
    try {
      // 调用封装好的连接逻辑
      await _bluetoothService.connectToDevice(_selectedDevice!);

      // 等待最多 5 秒，直到成功订阅特征值
      bool isSubscribed = false;
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        isSubscribed = _bluetoothService.isSubscribed;
        return !isSubscribed; // 当 isSubscribed = true 时退出循环
      }).timeout(const Duration(seconds: 5));

      if (isSubscribed) {
        Navigator.pushNamedAndRemoveUntil(context, "/root_app", (route) => false);
      } else {
        throw Exception("无法订阅特征值，请检查设备服务");
      }
    } on TimeoutException {
      showDialog(
        context: context,
        builder: (ctx) => const AlertDialog(
          title: Text("连接超时"),
          content: Text("无法在指定时间内订阅数据通道"),
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

    // 根据状态显示不同的文字
    String statusText;
    if (isConnected) {
      statusText = "已连接 Mini HAR";
    } else if (isConnecting) {
      statusText = "连接中...";
    } else {
      statusText = "未连接 Mini HAR";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("蓝牙连接"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 显示连接状态
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
              "确认设备电源开启，已在系统中绑定，点击下方按钮连接。",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Spacer(),

            // “连接”按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: (isConnecting || isConnected) ? null : _connectToDevice,
                child: _isConnecting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '连接',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 取消订阅，防止内存泄漏
    _connectionSubscription.cancel();
    _bondedSubscription?.cancel();
    super.dispose();
  }
}
