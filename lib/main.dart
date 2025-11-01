import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  final prefs = await SharedPreferences.getInstance();
  final hasProfile = prefs.containsKey('username') && prefs.containsKey('user_id');

  runApp(BolBolEsnafApp(hasProfile: hasProfile));
}

class BolBolEsnafApp extends StatelessWidget {
  final bool hasProfile;
  const BolBolEsnafApp({super.key, required this.hasProfile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BolBol Esnaf',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      initialRoute: hasProfile ? "/home" : "/profile",
      routes: {
        "/home": (context) => const HomePage(),
        "/profile": (context) => const ProfilePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
