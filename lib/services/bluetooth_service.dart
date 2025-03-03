import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final fb.FlutterBluePlus fbp = fb.FlutterBluePlus();
  fb.BluetoothDevice? _connectedDevice;

  // Define separate variables for each target characteristic.
  fb.BluetoothCharacteristic? _predictionCharacteristic;
  fb.BluetoothCharacteristic? _sensorCharacteristic;

  // Create separate StreamControllers if you want to handle the data separately.
  final StreamController<List<fb.BluetoothDevice>> _bondedDevicesController =
  StreamController<List<fb.BluetoothDevice>>.broadcast();
  final StreamController<List<fb.ScanResult>> _scanResultsController =
  StreamController<List<fb.ScanResult>>.broadcast();

  // Separate controllers for prediction and sensor data.
  final StreamController<List<int>> _predictionDataController =
  StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _sensorDataController =
  StreamController<List<int>>.broadcast();

  // Expose streams for external listeners.
  Stream<List<fb.BluetoothDevice>> get bondedDevicesStream =>
      _bondedDevicesController.stream;
  Stream<List<fb.ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;
  Stream<List<int>> get predictionDataStream => _predictionDataController.stream;
  Stream<List<int>> get sensorDataStream => _sensorDataController.stream;

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

  /// Connects to a selected device and discovers its services.
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

  /// Discovers services and subscribes to notifications for two specific characteristics.
  Future<void> discoverServices(fb.BluetoothDevice device) async {
    List<fb.BluetoothService> services = await device.discoverServices();
    for (fb.BluetoothService service in services) {
      for (fb.BluetoothCharacteristic characteristic in service.characteristics) {
        print("Discovered Characteristic: ${characteristic.uuid}");
        // Check for the prediction characteristic UUID.
        if (characteristic.uuid.toString().toLowerCase() ==
            "19b10012-e8f2-537e-4f6c-d104768a1214") {
          _predictionCharacteristic = characteristic;
          readCharacteristic(characteristic);
          monitorCharacteristic(characteristic, _predictionDataController);
        }
        // Check for the sensor data characteristic UUID.
        else if (characteristic.uuid.toString().toLowerCase() ==
            "19b10013-e8f2-537e-4f6c-d104768a1215") {
          _sensorCharacteristic = characteristic;
          readCharacteristic(characteristic);
          monitorCharacteristic(characteristic, _sensorDataController);
        }
      }
    }
  }

  /// Reads data from a characteristic.
  Future<void> readCharacteristic(fb.BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      String data = utf8.decode(value);
      print("Read Data from ${characteristic.uuid}: $data");
      // Here you might add the value to the corresponding stream if needed.
    } catch (e) {
      print("Error reading characteristic: $e");
    }
  }

  /// Subscribes to characteristic notifications and directs the data to the provided controller.
  void monitorCharacteristic(
      fb.BluetoothCharacteristic characteristic, StreamController<List<int>> controller) async {
    if (characteristic.properties.notify) {
      await characteristic.setNotifyValue(true);
      characteristic.lastValueStream.listen((value) {
        controller.add(value); // Send the received data to the appropriate stream.
      });
    }
  }

  /// Disconnects from the connected device.
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      print("Disconnected from device: ${_connectedDevice!.platformName}");
      _connectedDevice = null;
      _predictionCharacteristic = null;
      _sensorCharacteristic = null;
    }
  }

  void stopScan() {
    fb.FlutterBluePlus.stopScan();
  }

  void dispose() {
    _bondedDevicesController.close();
    _scanResultsController.close();
    _predictionDataController.close();
    _sensorDataController.close();
  }
}