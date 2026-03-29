import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry? padding;

  const ErrorMessage({
    super.key,
    required this.message,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.red.shade700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

