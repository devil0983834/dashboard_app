import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:io';
import '../widgets/device.dart';
import '../widgets/fun.dart';

bool useAPI = false;
String IpAdd = '';

class MyHome extends StatefulWidget {
  final BleController bleController = Get.put(BleController());

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<MyHome> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;
  final connectedDevicesData = <Map<String, dynamic>>[].obs;
  List<BluetoothDevice?> listDevices = [];
  @override
  void initState() {
    super.initState();
    _widgetOptions = _buildWidgetOptions();
    _loadDevices();
  }

  Future<List<BluetoothDevice?>> scanDevicesByMacList(
      List<String> macAddressesToFind) async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      // Bắt đầu quét thiết bị
      FlutterBluePlus.startScan(timeout: Duration(seconds: 1));

      // Lắng nghe kết quả quét
      final scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (int i = 0; i < macAddressesToFind.length; i++) {
          String macAddressToFind = macAddressesToFind[i];
          BluetoothDevice? foundDevice;

          for (ScanResult result in results) {
            String deviceMac = result.device.remoteId.toString();

            if (deviceMac == macAddressToFind) {
              foundDevice = result.device;
              break;
            }
          }
          listDevices.add(foundDevice);
        }
      });

      await Future.delayed(
          Duration(seconds: 1)); // Điều chỉnh thời gian nếu cần
      await scanSubscription.cancel();
      FlutterBluePlus.stopScan();
    }

    return listDevices;
  }

  List<Widget> _buildWidgetOptions() {
    return <Widget>[
      Obx(() {
        if (connectedDevicesData.isEmpty) {
          return Center(child: Text('No devices found'));
        }
        return DeviceList(
          listDevices: listDevices,
          data: connectedDevicesData,
          ble: widget.bleController,
        );
      }),
      Center(child: Text('Livingroom Devices')),
      Center(child: Text('Bedroom Devices')),
    ];
  }

  Future<void> updateIP(BluetoothDevice? device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<BluetoothService> services = await device!.discoverServices();
    List<int> value1 = await services.last.characteristics[2].read();
    String ip = String.fromCharCodes(value1);
    List<String> connectedDevicesData =
        prefs.getStringList('connectedDevices') ?? [];

    for (int i = 0; i < connectedDevicesData.length; i++) {
      Map<String, dynamic> deviceData = jsonDecode(connectedDevicesData[i]);

      if (device.remoteId.toString() == deviceData['macAddress']) {
        deviceData['ip'] = ip;
        connectedDevicesData[i] = jsonEncode(deviceData); // Cập nhật dữ liệu
        break;
      }
    }

    // Lưu danh sách thiết bị đã cập nhật vào SharedPreferences
    await prefs.setStringList('connectedDevices', connectedDevicesData);
  }

  Future<void> _loadDevices() async {
    try {
      RxList<Map<String, dynamic>> devicesData = await loadDevices();

      List<String> macAddresses = [];

      for (var device in devicesData) {
        macAddresses.add(device['macAddress']);
      }

      listDevices = await scanDevicesByMacList(macAddresses);

      setState(() {
        for (BluetoothDevice? device in listDevices) {
          updateIP(device);
          device?.connect();
        }
        listDevices;
        connectedDevicesData.assignAll(devicesData);
      });
    } catch (e) {
      print('Error loading devices: $e');
    }
  }

  Future<RxList<Map<String, dynamic>>> loadDevices() async {
    try {
      List<String> deviceDataList = await widget.bleController.getDeviceData();

      RxList<Map<String, dynamic>> data = <Map<String, dynamic>>[].obs;
      for (String deviceData in deviceDataList) {
        try {
          Map<String, dynamic> dataMap = jsonDecode(deviceData);
          data.add(dataMap);
        } catch (e) {
          print('Error decoding device data: $e');
        }
      }
      return data;
    } catch (e) {
      print('Error loading devices: $e');
      return <Map<String, dynamic>>[].obs;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_selectedIndex == 0) {
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E2026),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF1E2026),
        unselectedItemColor: Colors.white,
        selectedItemColor: Color(0xff498fff),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Tất cả',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.living),
            label: 'Livingroom',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedroom_child),
            label: 'Bedroom',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MyHomePage(bleController: widget.bleController),
            ),
          ).then((_) {
            _loadDevices(); // Refresh the device list after returning from the new page
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xff498fff),
      ),
    );
  }
}

class DeviceList extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final BleController ble;
  final List<BluetoothDevice?> listDevices;

  DeviceList(
      {required this.data, required this.listDevices, required this.ble});
  _DeviceList createState() => _DeviceList();
}

class _DeviceList extends State<DeviceList> {
  Map<String, bool> deviceStates = {};

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, dynamic>> getDeviceByMac(String a) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> connectedDevicesData =
        prefs.getStringList('connectedDevices') ?? [];

    for (int i = 0; i < connectedDevicesData.length; i++) {
      Map<String, dynamic> deviceData = jsonDecode(connectedDevicesData[i]);

      if (deviceData['macAddress'] == a) {
        return deviceData;
      }
    }
    return {};
  }

  Future<void> toggleDeviceState(
      bool newState, Map<String, dynamic> data, BluetoothDevice? device) async {
    List<BluetoothService>? services = [];
    IpAdd = data['ip'];
    data = await getDeviceByMac(data['macAddress']);
    setState(() {
      deviceStates[data['macAddress']] = newState;
    });

    if (data['useInternetLan'] == '0') {
      if (device != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              "BLE: ${device?.platformName}",
              style: TextStyle(color: Colors.black),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
        services = await device.discoverServices();
        String cmt =
            (deviceStates[device.remoteId.toString()] ?? false) ? 'ON' : 'OFF';

        try {
          if (services.isNotEmpty) {
            sendCommand("$cmt", services.last.characteristics[0]);
          }
        } catch (e) {
          print('Failed to discover services: $e');
        }
      } else {
        setState(() {
          deviceStates[data['macAddress']] = !newState;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              "Bluetooth is not enabled",
              style: TextStyle(color: Colors.black),
            ),
            content: Text(
              "Please enable Bluetooth in settings phone or in setting device.",
              style: TextStyle(color: Colors.black),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            "HTTP: $IpAdd, ${data['channel']} ${data['apiKey']}",
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
      if (newState) {
        turnOnLed(IpAdd);
      } else {
        turnOffLed(IpAdd);
      }
    }
  }

  Future<void> turnOnLed(String serverIp) async {
    try {
      final response = await http.get(Uri.parse('http://$serverIp/led/on'));
      if (response.statusCode == 200) {
        print("LED đã bật");
      } else {
        print("Lỗi khi bật LED: ${response.statusCode}");
      }
    } catch (e) {
      print("Không thể kết nối tới ESP32: $e");
    }
  }

  Future<void> turnOffLed(String serverIp) async {
    try {
      final response = await http.get(Uri.parse('http://$serverIp/led/off'));
      if (response.statusCode == 200) {
        print("LED đã tắt");
      } else {
        print("Lỗi khi tắt LED: ${response.statusCode}");
      }
    } catch (e) {
      print("Không thể kết nối tới ESP32: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: widget.data.map((deviceData) {
        BluetoothDevice? device;
        String deviceMacAddress = deviceData['macAddress'];

        for (BluetoothDevice? dev in widget.listDevices) {
          if (dev?.remoteId.toString() == deviceMacAddress) {
            device = dev;
          }
        }

        return DeviceTile(
          device: device,
          data: deviceData,
          isActive: deviceStates[deviceMacAddress] ?? false,
          onToggle: (newState) =>
              toggleDeviceState(newState, deviceData, device),
        );
      }).toList(),
    );
  }

  void sendCommand(
      String command, BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.write(command.codeUnits);
    } catch (e) {
      print('Failed to send command: $e');
    }
  }
}

Future<Map<String, String>?> getDeviceDataByMac(String macAddress) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> connectedDevicesData =
      prefs.getStringList('connectedDevices') ?? [];

  for (String deviceDataJson in connectedDevicesData) {
    Map<String, String> deviceData =
        Map<String, String>.from(jsonDecode(deviceDataJson));

    if (deviceData['macAddress'] == macAddress) {
      return deviceData;
    }
  }

  return null; // Không tìm thấy thiết bị với địa chỉ MAC này
}

class DeviceTile extends StatefulWidget {
  final Map<String, dynamic> data;
  final BluetoothDevice? device;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  DeviceTile({
    required this.device,
    required this.data,
    required this.isActive,
    required this.onToggle,
  });

  @override
  _DeviceTileState createState() => _DeviceTileState();
}

class _DeviceTileState extends State<DeviceTile> {
  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();
    data = widget.data;
  }

//
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF252F52),
      child: ListTile(
        leading: Switch(
          activeColor: Color(0xff498fff),
          value: widget.isActive,
          onChanged: widget.onToggle,
        ),
        title: Text(
          data['deviceName'],
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          data['macAddress'],
          style: TextStyle(color: Colors.white70),
        ),
        trailing: GestureDetector(
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) {
              return DeviceScreen(device: widget.device, dataMap: data);
            })).then((_) async {
              var updatedData = await getDeviceDataByMac(data['macAddress']);
              if (updatedData != null) {
                setState(() {
                  data = updatedData;
                });
              }
            });
          },
          child: Icon(Icons.settings, color: Colors.white),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final BleController bleController;

  MyHomePage({Key? key, required this.bleController}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.bleController.scanDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'BLE Scanner',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1E2026),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<List<ScanResult>>(
                  stream: widget.bleController.scanResults,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Expanded(
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final data = snapshot.data![index];
                              if (data.device.platformName == '') {
                                return SizedBox.shrink();
                              }
                              return Card(
                                color: Color(0xFF252F52), // Màu nền của Card
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Đặt bán kính bo tròn
                                ),
                                child: ListTile(
                                  title: Text(
                                    data.device.platformName ??
                                        'no namme device',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text('${data.device.isConnected} ',
                                      style: TextStyle(color: Colors.white)),
                                  trailing: Text(
                                      data.device.remoteId.toString(),
                                      style: TextStyle(color: Colors.white)),
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) {
                                    return DeviceScreen(device: data.device);
                                  })),
                                ),
                              );
                            }),
                      );
                    } else {
                      return Center(
                        child: Text("No Device Found"),
                      );
                    }
                  }),
              SizedBox(
                height: 10,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await checkPermissions();
              widget.bleController.scanDevices();
            },
            child: FaIcon(
              FontAwesomeIcons.syncAlt,
              size: 13,
            ),
            backgroundColor: Color(0xff498fff), // Màu nền của nút
          ),
        ));
  }

  Future checkPermissions() async {
    // Kiểm tra quyền Bluetooth và vị trí
    var bluetoothState = await FlutterBluePlus.adapterState.first;
    if (bluetoothState != BluetoothAdapterState.on) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            "Bluetooth is not enabled",
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            "Please enable Bluetooth in settings.",
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }

    // Yêu cầu quyền vị trí (đối với Android)
    if (Platform.isAndroid) {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        await Permission.locationWhenInUse.request();
      }
    }
  }
}
