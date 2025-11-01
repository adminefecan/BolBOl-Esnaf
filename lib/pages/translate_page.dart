import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  final TextEditingController _controller = TextEditingController();
  String translated = "";
  String targetLang = "en";
  bool loading = false;

  Future<void> translate() async {
    if (_controller.text.isEmpty) return;
    setState(() => loading = true);
    final url = Uri.parse(
        "https://bolbolesnaf.efecand.com.tr/api/apis/translate.php?text=${Uri.encodeComponent(_controller.text)}&to=$targetLang");
    final res = await http.get(url);
    final data = json.decode(res.body);
    if (data["translated"] != null) {
      setState(() => translated = data["translated"]);
    } else {
      setState(() => translated = "Çeviri başarısız.");
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌐 Çeviri"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Metin gir...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Hedef Dil: "),
                DropdownButton<String>(
                  value: targetLang,
                  items: const [
                    DropdownMenuItem(value: "en", child: Text("İngilizce")),
                    DropdownMenuItem(value: "de", child: Text("Almanca")),
                    DropdownMenuItem(value: "fr", child: Text("Fransızca")),
                    DropdownMenuItem(value: "ar", child: Text("Arapça")),
                    DropdownMenuItem(value: "ru", child: Text("Rusça")),
                    DropdownMenuItem(value: "tr", child: Text("Türkçe")),
                  ],
                  onChanged: (val) => setState(() => targetLang = val!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: translate,
              icon: const Icon(Icons.translate),
              label: const Text("Çevir"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            if (loading)
              const CircularProgressIndicator()
            else
              AnimatedOpacity(
                opacity: translated.isEmpty ? 0 : 1,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    translated,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
