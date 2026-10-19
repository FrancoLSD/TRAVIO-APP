import 'package:flutter/material.dart';

import '../../../core/widgets/app_header.dart';

class ConvertScreen extends StatelessWidget {
  const ConvertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: const [AppHeader()],
      ),
    );
  }
}
