import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final fb.FlutterBluePlus fbp = fb.FlutterBluePlus();
  fb.BluetoothDevice? _connectedDevice;
  fb.BluetoothCharacteristic? _targetCharacteristic;

  final StreamController<List<fb.BluetoothDevice>> _bondedDevicesController =
  StreamController<List<fb.BluetoothDevice>>.broadcast();
  final StreamController<List<fb.ScanResult>> _scanResultsController =
  StreamController<List<fb.ScanResult>>.broadcast();
  final StreamController<String> _dataController =
  StreamController<String>.broadcast();

  Stream<List<fb.BluetoothDevice>> get bondedDevicesStream =>
      _bondedDevicesController.stream;
  Stream<List<fb.ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;
  Stream<String> get dataStream => _dataController.stream;

  /// Initializes Bluetooth service.
  void initialize() {
    getBondedDevices();
    startScan();
  }

  /// Gets bonded (paired) Bluetooth devices.
  Future<void> getBondedDevices() async {
    try {
      List<fb.BluetoothDevice> devices = await fb.FlutterBluePlus.bondedDevices;
      _bondedDevicesController.add(devices);
      print("Bonded Devices: ${devices.map((d) => d.platformName).toList()}");
    } catch (e) {
      print("Error fetching bonded devices: $e");
    }
  }

  /// Starts scanning for available BLE devices.
  Future<void> startScan() async {
    fb.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    fb.FlutterBluePlus.scanResults.listen((results) {
      _scanResultsController.add(results);
      for (fb.ScanResult r in results) {
        print('Discovered device: ${r.device.platformName} (${r.device.remoteId})');
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      fb.FlutterBluePlus.stopScan();
    });
  }

  /// Connects to a selected bonded or scanned device.
  Future<void> connectToDevice(fb.BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      print("Connected to device: ${device.platformName}");
      discoverServices(device);
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  /// Discovers services and characteristics of the connected device.
  Future<void> discoverServices(fb.BluetoothDevice device) async {
    List<fb.BluetoothService> services = await device.discoverServices();
    for (fb.BluetoothService service in services) {
      for (fb.BluetoothCharacteristic characteristic in service.characteristics) {
        print("Discovered Characteristic: ${characteristic.uuid}");
        // 仅示例使用特定的 UUID（如 "2a37"），请根据你的设备实际情况修改
        if (characteristic.uuid.toString().toLowerCase() == "2a37") {
          _targetCharacteristic = characteristic;
          readCharacteristic(characteristic); // 读取一次
          monitorCharacteristic(characteristic); // 开启通知，实时更新
          return;
        }
      }
    }
  }

  /// Reads data from the target characteristic.
  Future<void> readCharacteristic(fb.BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      String data = utf8.decode(value);
      print("Read Data: $data");
      _dataController.add(data);
    } catch (e) {
      print("Error reading characteristic: $e");
    }
  }

  /// Subscribes to characteristic notifications.
  void monitorCharacteristic(fb.BluetoothCharacteristic characteristic) async {
    if (characteristic.properties.notify) {
      await characteristic.setNotifyValue(true);
      characteristic.lastValueStream.listen((value) {
        String data = value.isNotEmpty ? value.toString() : "No Data";
        print("Received Data: $data");
        _dataController.add(data);
      });
    }
  }

  /// Disconnects from the device.
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      print("Disconnected from device: ${_connectedDevice!.platformName}");
      _connectedDevice = null;
      _targetCharacteristic = null;
    }
  }

  void stopScan() {
    fb.FlutterBluePlus.stopScan();
  }

  void dispose() {
    _bondedDevicesController.close();
    _scanResultsController.close();
    _dataController.close();
  }
}
