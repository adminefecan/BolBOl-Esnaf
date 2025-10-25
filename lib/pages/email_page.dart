import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  String? generatedEmail;
  List inbox = [];
  bool loading = false;

  Future<void> createEmail() async {
    setState(() => loading = true);
    var url = Uri.parse("https://bolbolesnaf.efecand.com.tr/api/router.php?action=create_email");
    var res = await http.post(url, headers: {"Content-Type": "application/json"});
    var data = json.decode(res.body);
    setState(() {
      generatedEmail = data["email"];
      inbox.clear();
      loading = false;
    });
  }

  Future<void> getInbox() async {
    if (generatedEmail == null) return;
    setState(() => loading = true);
    var url = Uri.parse("https://bolbolesnaf.efecand.com.tr/api/router.php?action=get_inbox");
    var res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"email": generatedEmail}),
    );
    setState(() {
      inbox = json.decode(res.body);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("E-posta Servisleri")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: createEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Yeni E-posta Oluştur"),
            ),
            const SizedBox(height: 15),
            if (generatedEmail != null)
              Column(
                children: [
                  Text(
                    "📧 $generatedEmail",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: getInbox,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade500,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Gelen Kutusunu Görüntüle"),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            Expanded(
              child: inbox.isEmpty
                  ? const Center(child: Text("Henüz e-posta yok"))
                  : ListView.builder(
                      itemCount: inbox.length,
                      itemBuilder: (context, index) {
                        final mail = inbox[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.mail_outline),
                            title: Text(mail['subject'] ?? 'Konu Yok'),
                            subtitle: Text(mail['fromEmail'] ?? 'Gönderen Bilinmiyor'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
