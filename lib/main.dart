import 'package:flutter/material.dart';
import 'package:time_spy/ui/pages/app_usage_page.dart' show AppUsagePage;
import 'package:time_spy/ui/pages/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Spy',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
