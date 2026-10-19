import 'package:flutter/material.dart';

import '../../../core/widgets/app_header.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const AppHeader(),
          const SizedBox(height: 28),
          Text('Trips', style: text.headlineLarge),
        ],
      ),
    );
  }
}
