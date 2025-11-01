import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  int? userId;
  int? sessionId;
  bool loading = false; // Hem ilk yükleme hem de yanıt bekleme için

  final String _apiBaseUrl = "bolbolesnaf.efecand.com.tr";
  final String _getChatPath = "/api/ai/get_chat.php";
  final String _sendMessagePath = "/api/ai/send_message.php";

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      _showError("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }

    debugPrint("Kullanıcı ID'si bulundu: $userId");
    await _loadMessages();
  }

  // ⭐️ ESKİ MESAJLARI GETİR (GET ile çalışır)
  Future<void> _loadMessages() async {
    if (userId == null) return;

    setState(() {
      loading = true;
      _messages = [];
    });
    debugPrint("Eski mesajlar yükleniyor... (API: get_chat.php)");

    final uri = Uri.https(
      _apiBaseUrl,
      _getChatPath,
      {"user_id": "$userId"},
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 90));
      final data = jsonDecode(res.body);

      if (data["status"] == "ok") {
        setState(() {
          // ⭐️⭐️ SORUN BURADA OLABİLİR ⭐️⭐️
          // 'session_id' String mi geliyor yoksa int mi?
          // tryParse ile garantiliyoruz.
          sessionId = int.tryParse(data["session_id"].toString());

          _messages = (data["messages"] as List)
              .map<Map<String, String>>((e) => {
            "role": e["role"].toString(),
            "text": e["message"].toString(),
          })
              .toList();
        });

        // ⭐️ KONSOLU KONTROL ET ⭐️
        debugPrint("MESAJLAR YÜKLENDİ. SESSION ID AYARLANDI: $sessionId");

      } else {
        _showError(data["message"] ?? "Mesajlar yüklenemedi.");
        debugPrint("API Hatası (get_chat.php): ${data["message"]}");
      }
    } catch (e) {
      _showError("Bağlantı hatası (get_chat): $e");
      debugPrint("Flutter Hatası (get_chat): $e");
    } finally {
      setState(() {
        loading = false;
      });
      _scrollToBottom();
    }
  }

  // ⭐️ YENİ MESAJ GÖNDER (GET ile çalışır)
  Future<void> _sendMessage() async {
    final msg = _controller.text.trim();

    // ⭐️ KONSOLU KONTROL ET ⭐️
    // Mesaj gönder butonuna bastığında burası çalışır:
    debugPrint("Mesaj gönderiliyor... Mevcut Session ID: $sessionId");

    // ⭐️⭐️ ASIL SORUN %99 BURADA ⭐️⭐️
    // Eğer sessionId hala null veya 0 ise, API'ye gitmez.
    if (sessionId == null || sessionId == 0) {
      debugPrint("HATA: Session ID 0 veya null olduğu için mesaj GÖNDERİLEMEDİ.");
      _showError("Oturum bilgisi alınamadı. Sayfayı yenileyip tekrar deneyin.");
      return; // Fonksiyondan çık
    }

    if (msg.isEmpty || userId == null || loading) {
      debugPrint("İşlem engellendi: (msg: $msg, userId: $userId, loading: $loading)");
      return;
    }

    _controller.clear();
    setState(() {
      _messages.add({"role": "user", "text": msg});
      loading = true;
    });
    _scrollToBottom();

    final uri = Uri.https(
      _apiBaseUrl,
      _sendMessagePath,
      {
        "user_id": "$userId",
        "session_id": "$sessionId", // ⭐️ Buraya 0 gitmemeli
        "message": msg,
      },
    );

    debugPrint("API'ye istek gidiyor: $uri"); // URL'i konsolda gör

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 90));
      final data = jsonDecode(res.body);

      debugPrint("API Yanıtı (send_message.php): $data"); // API'den ne döndü?

      if (data["status"] == "ok") {
        setState(() {
          _messages = (data["messages"] as List)
              .map<Map<String, String>>((e) => {
            "role": e["role"].toString(),
            "text": e["message"].toString(),
          })
              .toList();
        });
      } else {
        _showError(data["message"] ?? "Mesaj gönderilemedi.");
        setState(() {
          _messages.removeLast(); // Hata olduğu için son eklenen 'user' mesajını kaldır
        });
      }
    } catch (e) {
      _showError("Bağlantı hatası (send_message): $e");
      debugPrint("Flutter Hatası (send_message): $e");
      setState(() {
        _messages.removeLast();
      });
    }

    setState(() {
      loading = false;
    });
    _scrollToBottom();
  }

  // Hata gösterme fonksiyonu
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Listenin en sonuna kaydıran fonksiyon
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yapay Zekâ Asistanı 🤖"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: (loading && _messages.isEmpty)
                ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m["role"] == "user";
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.orange[200]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m["text"] ?? "",
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (loading && _messages.isNotEmpty)
            const LinearProgressIndicator(color: Colors.orange),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Mesajınızı yazın...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: loading ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}