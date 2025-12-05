import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

/// Affiche un SnackBar moderne avec icône et animation
void showModernSnackBar(
  BuildContext context, {
  required String message,
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = _getColor(type);
  final icon = _getIcon(type);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: duration,
      elevation: 6,
    ),
  );
}

Color _getColor(SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return const Color(0xFF007A3F);
    case SnackBarType.error:
      return const Color(0xFFEA0707);
    case SnackBarType.warning:
      return const Color(0xFFFFA000);
    case SnackBarType.info:
      return const Color(0xFF2196F3);
  }
}

IconData _getIcon(SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return Icons.check_circle;
    case SnackBarType.error:
      return Icons.error;
    case SnackBarType.warning:
      return Icons.warning;
    case SnackBarType.info:
      return Icons.info;
  }
}
