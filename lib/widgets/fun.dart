import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BleController extends GetxController {
  FlutterBluePlus ble = FlutterBluePlus();
  BluetoothCharacteristic? characteristic;
  BluetoothDevice? device;

  var connectedDevices = <BluetoothDevice>[].obs;

  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      // Start scanning for devices
      FlutterBluePlus.startScan(timeout: Duration(seconds: 15));

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          print('Device found: ${result.device.platformName}');
        }
      });

      // Wait for the scan to complete
      await Future.delayed(Duration(seconds: 15));
      FlutterBluePlus.stopScan();
    }
  }

  Future<BluetoothDevice?> scanDeviceMac(String macAddressToFind) async {
    BluetoothDevice? foundDevice;

    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      // Start scanning for devices
      FlutterBluePlus.startScan(timeout: Duration(seconds: 15));

      // Listen for scan results
      final scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          String deviceMac = result.device.remoteId.toString(); // Changed to id
          // Compare MAC address of the device with the one to find
          if (deviceMac == macAddressToFind) {
            foundDevice = result.device;
            // Stop scanning and cancel the subscription
            FlutterBluePlus.stopScan();
            break;
          }
        }
      });

      // Wait for the scan to complete or the device to be found
      await Future.delayed(Duration(seconds: 15));
      await scanSubscription.cancel();
      FlutterBluePlus.stopScan();

      return foundDevice;
    }
    return null;
  }

  // Function to retrieve and update connected devices
  Future<void> getConnectedDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> connectedDevicesData =
        prefs.getStringList('connectedDevices') ?? [];

    // Start BLE scan
    FlutterBluePlus.startScan(timeout: Duration(seconds: 15));

    // Listen to scan results and check against stored MAC addresses
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        String deviceMac = result.device.remoteId.toString(); // Changed to id
        for (String jsonString in connectedDevicesData) {
          try {
            Map<String, dynamic> deviceData = jsonDecode(jsonString);
            if (deviceData['macAddress'] == deviceMac &&
                !connectedDevices.contains(result.device)) {
              connectedDevices.add(result.device);
            }
          } catch (e) {
            print('Error decoding JSON: $e');
          }
        }
      }
    });

    await Future.delayed(Duration(seconds: 15));
    FlutterBluePlus.stopScan();
  }

  Future<List<String>> getDeviceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> connectedDevicesData =
        prefs.getStringList('connectedDevices') ?? [];
    return connectedDevicesData;
  }

  // Function to add a device with 3 linked values: deviceName, macAddress, and apiKey
  Future<void> addDevice(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    List<int> value = await services.last.characteristics[1].read();
    String apiKey = String.fromCharCodes(value);
    List<int> value1 = await services.last.characteristics[2].read();
    String ip = String.fromCharCodes(value1);
    List<int> value2 = await services.last.characteristics[3].read();
    String channel = String.fromCharCodes(value2);

    String macAddress = device.remoteId.toString();
    String deviceName = device.platformName;

    // Create a map to store the device data
    Map<String, String> deviceData = {
      'deviceName': deviceName,
      'macAddress': macAddress,
      'useInternetLan': '1',
      'apiKey': apiKey,
      'channel': channel,
      'ip': ip
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> connectedDevicesData =
        prefs.getStringList('connectedDevices') ?? [];

    // connectedDevicesData.add(jsonEncode(deviceData));
    // await prefs.setStringList('connectedDevices', connectedDevicesData);
    bool deviceExists = false;
    deviceExists = connectedDevicesData.any((data) {
      Map<String, dynamic> existingDeviceData = jsonDecode(data);
      return existingDeviceData['macAddress'] == macAddress;
    });

    if (!deviceExists) {
      // Convert the map to JSON and store it
      connectedDevicesData.add(jsonEncode(deviceData));
      await prefs.setStringList('connectedDevices', connectedDevicesData);
    } else {
      print('Device with MAC address $macAddress already exists. Skipping...');
    }
  }

// Function to remove a device with 3 linked values
  Future<void> removeDevice(BluetoothDevice device) async {
    String macAddress = device.remoteId.toString();

    // Get the instance of SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the list of connected devices from SharedPreferences
    List<String> connectedDevicesData =
        prefs.getStringList('connectedDevices') ?? [];

    // Check if the device exists in the list and remove it
    connectedDevicesData.removeWhere((jsonString) {
      try {
        Map<String, dynamic> deviceData = jsonDecode(jsonString);

        // Ensure the MAC address exists in the JSON data
        if (deviceData['macAddress'] != null &&
            deviceData['macAddress'] == macAddress) {
          return true; // Device found and should be removed
        }
      } catch (e) {
        print('Error decoding JSON: $e');
      }
      return false; // Keep this device in the list if it doesn't match
    });

    // Update SharedPreferences with the new list
    await prefs.setStringList('connectedDevices', connectedDevicesData);

    print("Device removed: MAC: $macAddress");
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
}


  // Function to add a device to the connected devices list
  // Future<void> addDevice(BluetoothDevice device) async {
  //   String macAddress = device.remoteId.toString();
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> connectedDevices1 =
  //       prefs.getStringList('connectedDevices') ?? [];
  //   List<String> connectedDevices2 =
  //       prefs.getStringList('UUID') ?? [];
  //   if (!connectedDevices1.contains(macAddress)) {
  //     connectedDevices1.add(macAddress);
  //     connectedDevices2.add(macAddress);
  //     await prefs.setStringList('connectedDevices', connectedDevices1);
  //   }
  // }

  // // Function to remove a device from the connected devices list
  // Future<void> removeDevice(BluetoothDevice device) async {
  //   String macAddress = device.remoteId.toString();
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> connectedDevices1 =
  //       prefs.getStringList('connectedDevices') ?? [];

  //   if (connectedDevices1.contains(macAddress)) {
  //     connectedDevices1.remove(macAddress);
  //     await prefs.setStringList('connectedDevices', connectedDevices1);
  //   }
  // }




  // Future<List<String>> getConnectedDevices() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.getStringList('connectedDevices') ?? [];
  // }

  // Future<void> autoConnectLastDevice() async {
  //   List<String> connectedDevices1 = await getConnectedDevices();
  //   if (await Permission.bluetoothScan.request().isGranted) {
  //     if (await Permission.bluetoothConnect.request().isGranted) {
  //       FlutterBluePlus.startScan(timeout: Duration(seconds: 15));

  //       FlutterBluePlus.scanResults.listen((results) {
  //         for (ScanResult result in results) {
  //           for (String macAddress in connectedDevices1) {
  //             // Tạo kết nối với thiết bị theo địa chỉ MAC đã lưu
  //             if (macAddress.toString() == result.device.remoteId.toString()) {}
  //             // Xử lý kết nối tiếp theo (ví dụ: đọc dữ liệu, gửi lệnh)
  //           }
  //         }
  //       });
  //       await Future.delayed(Duration(seconds: 15));
  //       FlutterBluePlus.stopScan();
  //     }
  //   }
  // }