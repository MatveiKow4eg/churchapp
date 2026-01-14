import 'package:flutter/material.dart';

/// Deprecated: server selection is removed.
///
/// Kept only to avoid build errors if some legacy reference remains.
/// The app uses a fixed production API URL (https://api.kovcheg.ee).
class ServerSetupScreen extends StatelessWidget {
  const ServerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Server setup has been removed in production builds.'),
        ),
      ),
    );
  }
}
