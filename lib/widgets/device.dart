import 'dart:ffi';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../pages/my_home.dart';
import '../widgets/fun.dart';

class DeviceScreen extends StatefulWidget {
  final Map<String, dynamic>? dataMap;
  final BluetoothDevice? device;
  DeviceScreen({
    Key? key,
    this.device,
    this.dataMap,
  }) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<BluetoothService>? _services;
  String connecTopple = '';
  bool useAPI = false;
  bool isBLE = false;
  bool isGet = false;
  bool useInternet = false;
  String apiKey = '';
  late Future<List<FlSpot>> _spotsFuture = Future.value([]);

  List<dynamic> dataThingSpeak = [];

  @override
  void initState() {
    super.initState();

    if (widget.dataMap != null) {
      isGet = false;
      _spotsFuture = _grabData();
      if (widget.dataMap?['useInternetLan'] == '1') {
        useInternet = true;
      } else {
        useInternet = false;
      }
    }
    if (widget.device != null) {
      if (widget.device?.isConnected == true) {
        connecTopple = "Disconnect";
      } else {
        connecTopple = "Connect";
      }

      isBLE = true;
    } else {
      connecTopple = "No found device with BLE";
      isBLE = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dataMap?['deviceName'] ?? widget.device?.platformName,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1E2026),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  StreamBuilder<bool>(
                    stream: Stream.value(useInternet),
                    initialData: null,
                    builder: (c, snapshot) => ListTile(
                      leading:
                          (snapshot.data == BluetoothConnectionState.connected)
                              ? Icon(Icons.bluetooth_connected)
                              : Icon(Icons.bluetooth_disabled),
                      title: Text(
                        widget.dataMap?['macAddress'] ??
                            widget.device?.remoteId.toString(),
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(widget.dataMap?['ip'] ?? ''),
                      trailing: TextButton(
                        child: Text(isBLE ? "Show Services" : "No Services"),
                        onPressed: () {
                          discoverServices();
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Use Internet LAN",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            Switch(
                              value: useInternet,
                              onChanged: (value) {
                                setState(() {
                                  useInternet = value;
                                  updateUseInternetLan(value ? '1' : '0');
                                });
                                if (value == false) {}
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            isGet
                                ? SizedBox.shrink()
                                : FutureBuilder<List<FlSpot>>(
                                    future: _spotsFuture,
                                    initialData: [],
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Error: ${snapshot.error}'));
                                      } else if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return Center(
                                            child: Text('No data available'));
                                      } else {
                                        return GraphTemp(
                                          size: 2,
                                          thingdata: snapshot.data!,
                                        );
                                      }
                                    },
                                  )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (widget.device != null) {
                    if (widget.device!.isConnected) {
                      await widget.device?.disconnect();
                      setState(() {
                        connecTopple = 'Connect';
                      });
                      await removeDevice(widget.device!);
                      await Get.find<BleController>()
                          .removeDevice(widget.device!);
                    } else {
                      await widget.device?.connect();
                      setState(() {
                        connecTopple = 'Disconnect';
                      });
                      await addDevice(widget.device!);
                      await Get.find<BleController>().addDevice(widget.device!);
                    }
                  }
                },
                child: Text(
                  connecTopple,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<FlSpot>> _grabData() async {
    try {
      List<FlSpot> spots = await _fetchData();
      setState(() {
        _spotsFuture = Future.value(spots);
      });
    } catch (e) {
      print('Error fetching data: $e');
    }

    return _spotsFuture;
  }

  // Define the async method
  Future<List<FlSpot>> _fetchData() async {
    List<dynamic> data = [];
    try {
      data = await fetchData();
      setState(() {
        dataThingSpeak = data;
      });

      return await fetchDataFromThingSpeak(data);
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  Future<List<FlSpot>> fetchDataFromThingSpeak(data) async {
    List<FlSpot> spots = [];
    for (var i = 0; i < 6; i++) {
      // Trục X theo giờ (hoặc thời gian), tính từ dữ liệu nhận được
      String createdAt = data[i]['created_at'];
      DateTime time = DateTime.parse(createdAt);

      double x = ((time.hour + 7) * 60 + time.minute).toDouble();

      double y = (double.parse(data[i]['field3'] ?? '0') * 100).round() / 100;

      if (!x.isInfinite && !x.isNaN && !y.isInfinite && !y.isNaN) {
        spots.add(FlSpot(x, y));
      }
    }

    return spots;
  }

  Future<List<dynamic>> fetchData() async {
    List<dynamic> data = [];

    final url =
        'https://api.thingspeak.com/channels/${widget.dataMap?['channel']}/fields/3.json?api_key=${widget.dataMap?['apiKey']}&results=6';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        data = jsonData['feeds'] ?? [];
        print(data);
      });
    } else {
      throw Exception('Failed to load data');
    }
    return data;
  }

  Future<void> updateUseInternetLan(String a) async {
    // Lấy đối tượng SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Lấy danh sách các thiết bị đã kết nối
    List<String> connectedDevicesData =
        prefs.getStringList('connectedDevices') ?? [];

    // Tìm và cập nhật thiết bị có địa chỉ MAC tương ứng trong connectedDevicesData
    for (int i = 0; i < connectedDevicesData.length; i++) {
      Map<String, dynamic> deviceData = jsonDecode(connectedDevicesData[i]);

      if (deviceData['macAddress'] == widget.dataMap?['macAddress']) {
        deviceData['useInternetLan'] = a;
        connectedDevicesData[i] = jsonEncode(deviceData); // Cập nhật dữ liệu
        break;
      }
    }

    // Lưu danh sách thiết bị đã cập nhật vào SharedPreferences
    await prefs.setStringList('connectedDevices', connectedDevicesData);
  }

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

  Future<void> discoverServices() async {
    if (widget.device != null) {
      try {
        List<BluetoothService> services =
            await widget.device!.discoverServices();
        setState(() {
          _services = services;
        });
      } catch (e) {
        print('Failed to discover services: $e');
      }
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            "Services",
            style: TextStyle(color: Colors.black),
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _services?.length,
              itemBuilder: (context, index) {
                final service = _services?[index];
                final characteristics = service?.characteristics;

                return ExpansionTile(
                  title: Text("Service UUID: ${service?.uuid}"),
                  children: characteristics!.map((characteristic) {
                    return ListTile(
                      title:
                          Text("Characteristic UUID: ${characteristic.uuid}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Properties: ${characteristic.properties}"),
                          // Read the value asynchronously
                          FutureBuilder<List<int>>(
                            future: characteristic.read(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text("Reading...");
                              } else if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              } else if (snapshot.hasData) {
                                return Text(
                                    "Value: ${String.fromCharCodes(snapshot.data!)}");
                              } else {
                                return Text("No data");
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
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
  }
}

class GraphTemp extends StatelessWidget {
  final int size;
  final List<FlSpot> thingdata;

  GraphTemp({
    required this.size,
    required this.thingdata,
  });

  @override
  Widget build(BuildContext context) {
    final validData = thingdata.where((point) => point.y > 0).toList();
    final double minX = validData.isNotEmpty ? validData.first.x : 0;
    final double maxX = validData.isNotEmpty ? validData.last.x : 1;
    final HeightScreen = MediaQuery.of(context).size.height;
    final WidthScreen = MediaQuery.of(context).size.width;

    final Set<double> xValuesWithData = thingdata.map((spot) => spot.x).toSet();

    return Container(
      width: WidthScreen * 0.5 * size - 12,
      padding: const EdgeInsets.only(top: 12, right: 12, bottom: 0, left: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF252F52),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFF252F52), width: 2),
      ),
      height: HeightScreen * 0.25,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots:
                  thingdata.map((point) => FlSpot(point.x, point.y)).toList(),
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
          ],
          borderData: FlBorderData(
            border: const Border(bottom: BorderSide(), left: BorderSide()),
          ),
          gridData: FlGridData(show: true),
          minX: minX,
          maxX: maxX,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value.isNaN || value.isInfinite) {
                    return const SizedBox();
                  }

                  if (xValuesWithData.contains(value)) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        minuToHouse(value),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value.isNaN || value.isInfinite) {
                    return const SizedBox();
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}

String minuToHouse(double value) {
  var hour = (value ~/ 60).toInt();
  var minute = (value % 60).toInt();

  if (hour > 24) {
    hour = hour - 24;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
