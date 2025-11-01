import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CryptoPage extends StatefulWidget {
  const CryptoPage({super.key});

  @override
  State<CryptoPage> createState() => _CryptoPageState();
}

class _CryptoPageState extends State<CryptoPage> {
  final TextEditingController _controller = TextEditingController(text: "bitcoin");
  Map<String, dynamic>? prices;
  bool loading = false;

  Future<void> fetchCrypto() async {
    setState(() => loading = true);
    final url = Uri.parse(
        "https://bolbolesnaf.efecand.com.tr/api/apis/crypto.php?symbol=${_controller.text}");
    try {
      final res = await http.get(url);
      final data = json.decode(res.body);
      if (data["prices"] != null) {
        setState(() => prices = data["prices"]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kripto bulunamadı.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bağlantı hatası: $e")),
      );
    }
    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchCrypto();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("💰 Kripto / Finans"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Kripto adı (örn: bitcoin, ethereum, dogecoin)",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onSubmitted: (_) => fetchCrypto(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchCrypto,
              icon: const Icon(Icons.refresh),
              label: const Text("Fiyatları Getir"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            if (loading)
              const CircularProgressIndicator()
            else if (prices != null)
              Column(
                children: [
                  _priceCard("USD", prices!["usd"]),
                  _priceCard("EUR", prices!["eur"]),
                  _priceCard("TRY", prices!["try"]),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _priceCard(String currency, dynamic value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(currency,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
