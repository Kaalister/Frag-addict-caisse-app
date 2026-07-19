import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../ui/root_shell.dart';
import '../ui/theme.dart';

class TillyApp extends StatefulWidget {
  const TillyApp({super.key});

  @override
  State<TillyApp> createState() => _TillyAppState();
}

class _TillyAppState extends State<TillyApp> {
  final controller = AppController();
  late Color primaryColor;

  @override
  void initState() {
    super.initState();
    primaryColor = controller.primaryColor;
    controller.addListener(_updateTheme);
  }

  @override
  void dispose() {
    controller
      ..removeListener(_updateTheme)
      ..dispose();
    super.dispose();
  }

  void _updateTheme() {
    if (controller.primaryColor.toARGB32() == primaryColor.toARGB32()) return;
    setState(() => primaryColor = controller.primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tilly',
      theme: caisseTheme(primaryColor),
      home: RootShell(controller: controller),
    );
  }
}
