import 'package:flutter/material.dart';

class MaintenanceModeScreen extends StatelessWidget {
  final String message;

  const MaintenanceModeScreen({
    super.key,
    this.message = 'NextWave is currently under maintenance. Please check back soon!',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Maintenance icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: const Color(0xFF30363D), width: 2),
                ),
                child: const Icon(
                  Icons.construction,
                  size: 60,
                  color: Color(0xFFFFBF00),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                '🚧 Under Maintenance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Animated loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "We'll be back shortly!",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
