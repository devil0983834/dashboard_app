import 'package:flutter/material.dart';

class RoundedCircularButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed; // Thêm hàm callback onPressed

  const RoundedCircularButton(
      {super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // Sử dụng hàm callback
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF252F52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
