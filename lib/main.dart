import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe yerel tarih formatlarını başlat
  await initializeDateFormatting('tr_TR', null)
      .catchError((e) => print("Locale yüklenemedi: $e"));

  runApp(const BolBolEsnafApp());
}

class BolBolEsnafApp extends StatelessWidget {
  const BolBolEsnafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BolBol Esnaf',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
