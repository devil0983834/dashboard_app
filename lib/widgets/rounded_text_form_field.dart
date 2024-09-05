import 'package:flutter/material.dart';

class RoundedTextFormField extends StatelessWidget {
  final bool obscureText;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;

  const RoundedTextFormField({
    super.key,
    this.obscureText = false,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(67, 71, 77, 0.08),
            spreadRadius: 10,
            blurRadius: 40,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF252F52),
            borderRadius: BorderRadius.all(
              Radius.circular(100),
            ),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(
                prefixIcon,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              hintStyle: const TextStyle(
                fontSize: 10,
                color: Color.fromRGBO(
                  131,
                  143,
                  160,
                  100,
                ),
              ),
              hintText: hintText,
            ),
            obscureText: obscureText,
          ),
        ),
      ),
    );
  }
}
