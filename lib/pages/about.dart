import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DisplayDataScreen extends StatefulWidget {
  @override
  _DisplayDataScreenState createState() => _DisplayDataScreenState();
}

class _DisplayDataScreenState extends State<DisplayDataScreen> {
  List<Map<String, dynamic>> connectedDevices = [];

  @override
  void initState() {
    super.initState();
    _loadConnectedDevices();
  }

  Future<void> _loadConnectedDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? devicesData = prefs.getStringList('connectedDevices');

    if (devicesData != null) {
      setState(() {
        connectedDevices = devicesData.map((data) {
          return Map<String, dynamic>.from(jsonDecode(data));
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E2026),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: connectedDevices.length,
        itemBuilder: (context, index) {
          final device = connectedDevices[index];
          return ListTile(
            title: Text(device['deviceName'] ?? 'No Name'),
            subtitle: Text('MAC: ${device['macAddress']}'),
          );
        },
      ),
    );
  }
}
