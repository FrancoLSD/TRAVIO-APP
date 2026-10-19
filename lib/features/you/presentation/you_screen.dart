import 'package:flutter/material.dart';

import '../../../core/widgets/app_header.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const AppHeader(),
          const SizedBox(height: 28),
          Text('You', style: text.headlineLarge),
          const SizedBox(height: 6),
          Text('Your plan and preferences.', style: text.bodyMedium),
        ],
      ),
    );
  }
}
