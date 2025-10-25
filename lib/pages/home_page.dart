import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart';
import 'email_page.dart';
import 'news_page.dart';
import 'translate_page.dart';
import 'crypto_page.dart';
import 'weather_page.dart'; // 👈 hava durumu sayfasını dahil ettik

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        "title": "E-posta Servisleri",
        "icon": Icons.email,
        "page": const EmailPage()
      },
      {
        "title": "Hava Durumu",
        "icon": Icons.cloud,
        "page": const WeatherPage() // 👈 aktif hale getirildi
      },
      {"title": "Haberler",
        "icon": Icons.newspaper,
        "page": const NewsPage()
      },
      {"title": "Çeviri",
        "icon": Icons.translate,
        "page": const TranslatePage()
      },
      {"title": "Kripto / Finans",
        "icon": Icons.currency_bitcoin,
        "page": const CryptoPage()
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("BolBol Esnaf",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return CategoryCard(
            title: cat["title"] as String,
            icon: cat["icon"] as IconData,
            onTap: cat["page"] != null
                ? () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => cat["page"] as Widget),
            )
                : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                    Text("Bu kategori yakında aktif olacak 🚀")),
              );
            },
          );
        },
      ),
    );
  }
}
