import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool loading = false;
  List<dynamic> newsList = [];
  String selectedCategory = "Gündem";
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    "Gündem",
    "Ekonomi",
    "Teknoloji",
    "Spor",
    "Sağlık",
    "Dünya"
  ];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews([String? query]) async {
    setState(() => loading = true);
    final q = query ?? selectedCategory;
    final url = Uri.parse(
        "https://bolbolesnaf.efecand.com.tr/api/apis/news.php?q=$q");
    try {
      final res = await http.get(url);
      final data = json.decode(res.body);
      if (data["articles"] != null) {
        setState(() => newsList = data["articles"]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Haber bulunamadı.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bağlantı hatası: $e")),
      );
    }
    setState(() => loading = false);
  }

  void showNewsPopup(dynamic n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  n["title"] ?? "Başlık Yok",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (n["source"] != null && n["source"] != "")
                  Text("Kaynak: ${n["source"]}",
                      style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
                Text(
                  n["desc"] ?? "Açıklama bulunamadı.",
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.public),
                    label: const Text("Kaynağa Git"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final url = n["url"];
                      if (url != null && url.isNotEmpty) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Bağlantı açılamadı.")),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📰 Haberler"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Arama
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Haber ara...",
                prefixIcon: const Icon(Icons.search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) fetchNews(val);
              },
            ),
          ),
          // 🔸 Kategori çubuğu
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final selected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (val) {
                      setState(() => selectedCategory = cat);
                      fetchNews(cat);
                    },
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 🔹 Haber listesi
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, i) {
                final n = newsList[i];
                return GestureDetector(
                  onTap: () => showNewsPopup(n),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n["title"] ?? "Başlık Yok",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(
                            n["desc"] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n["source"] ?? "",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
