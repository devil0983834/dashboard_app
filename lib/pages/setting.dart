import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../consts.dart';

class SettingPage extends StatefulWidget {
  final User user;
  const SettingPage({Key? key, required this.user}) : super(key: key);
  @override
  _UpdateDataPageState createState() => _UpdateDataPageState();
}

class _UpdateDataPageState extends State<SettingPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String? email;
  int parseIntSafe(String? value) {
    if (value == null || value.isEmpty) {
      return 0; // Default value or handle as needed
    }
    try {
      return int.parse(value);
    } catch (e) {
      print('Error parsing integer: $e');
      return 0; // Default value or handle as needed
    }
  }

  String parseStringSafe(String? value) {
    if (value == null || value.isEmpty) {
      return ''; // Default value or handle as needed
    }
    return value; // Default value or handle as needed
  }

  Future<void> fetchData() async {
    email = await getUserEmail();
    final response = await http.post(
      Uri.parse('http://$IP:3000/getDataWithEmail'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
      }),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      setState(() {
        _nameController.text = data["displayName"] ?? '';
        _ageController.text = data["age"]?.toString() ?? '';
        _phoneController.text = data["phoneNumber"] ?? '';
        _cityController.text = data["city"] ?? '';
      });
    } else if (response.statusCode == 404) {
      print('Email not found');
    } else {
      throw Exception('Failed to send email');
    }
  }

  Future<void> updateData() async {
    email = await getUserEmail();
    // URL API của bạn để cập nhật dữ liệu lên MongoDB
    final url = Uri.parse('http://$IP:3000/updateData');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'email': email,
        'displayName': parseStringSafe(_nameController.text),
        'age': parseIntSafe(_ageController.text),
        'city': parseStringSafe(_cityController.text),
        'phoneNumber': parseStringSafe(_phoneController.text),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Data updated successfully'),
      ));
    } else {
      throw Exception('Failed to update data');
    }
  }

  Future<String?> getUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return user.email; // Lấy email của user
    } else {
      return null; // User chưa đăng nhập
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch data khi trang được tải
  }

  void dispose() {
    // Giải phóng tài nguyên của controller khi không còn sử dụng
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // String emailName = widget.user.email ?? 'default@example.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('Setting', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E2026),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: 'City'),
            ),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Age'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateData,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
