import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // EKLENDİ
  List messages = [];
  String? username;
  String? photoUrl;
  int? userId;
  bool loading = false;
  bool _isSending = false; // EKLENDİ: Mesaj gönderilirken yenilemeyi durdur
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // DÜZELTME: Yükleme ekranı ve zamanlayıcı mantığı
    loading = true; // Yüklemeyi başlat
    _loadUser().then((_) {
      _fetchMessages().then((_) {
        // İlk yükleme bitti
        if (mounted) setState(() => loading = false);
        _scrollToBottom(jump: true); // Anında en alta git

        // Zamanlayıcıyı ilk yüklemeden *sonra* başlat
        _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          _fetchMessages();
        });
      });
    });
  }

  /// Kullanıcı bilgilerini telefondan yükler
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString("username");
    photoUrl = prefs.getString("photo_url");
    userId = prefs.getInt("user_id");
    if (mounted) setState(() {});
  }

  /// Sunucudan mesajları çeker
  Future<void> _fetchMessages() async {
    // DÜZELTME: Zaten mesaj gönderiyorsak veya sayfa kapandıysa yenileme
    if (!mounted || _isSending) return;

    try {
      final res = await http.get(
        Uri.parse("https://bolbolesnaf.efecand.com.tr/api/chat/get_messages.php"),
      );

      // --- HATA ÇÖZÜMÜ BAŞLANGIÇ ---
      // Gelen veriyi (bodyBytes) önce bir string'e dönüştür
      final String responseBody = utf8.decode(res.bodyBytes);

      // Gelen string'in BOŞ olup olmadığını veya
      // geçerli bir JSON ({ ile) başlayıp başlamadığını KONTROL ET
      if (responseBody.isEmpty || !responseBody.trim().startsWith("{")) {
        // Eğer boşsa veya JSON değilse, hata yazdır ve işlemi durdur
        debugPrint("Sunucudan boş veya geçersiz JSON alındı: $responseBody");
        return; // Fonksiyondan çık, çökme
      }

      // Artık verinin boş olmadığından eminiz, şimdi decode edebiliriz
      final data = jsonDecode(responseBody);
      // --- HATA ÇÖZÜMÜ SON ---

      if (mounted && data["status"] == "success") {
        setState(() => messages = data["messages"]);
      }
    } catch (e) {
      // jsonDecode yine de başarısız olursa (örn: bozuk JSON)
      debugPrint("Mesaj çekme hatası (catch): $e");
    }
  }

  /// Yeni mesaj gönderir
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || userId == null || _isSending) return;

    if (mounted) setState(() => _isSending = true);

    // EKLENDİ: Optimistic UI (Anında Ekranda Gösterme)
    // Sunucudan yanıt beklemeden mesajı listeye ekle
    final optimisticMsg = {
      // id yok (çünkü henüz DB'de değil)
      "user_id": userId,
      "username": username,
      "message": text,
      "photo_url": photoUrl,
      "created_at": DateTime.now().toIso8601String() // O anın saatini ekle
    };

    setState(() {
      messages.add(optimisticMsg);
      _controller.clear();
    });
      try {
        // DÜZELTME: Sunucunun yanıtını 'response' değişkenine al
        final response = await http.post(
          Uri.parse("https://bolbolesnaf.efecand.com.tr/api/chat/send_message.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "message": text,
          }),
        );

        // GEÇİCİ DEBUG: Sunucudan ne yanıt geldiğini konsola yazdır
        debugPrint("Mesaj Gönderme Yanıtı: ${response.body}");

        // DÜZELTME: Yanıta göre işlem yap
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          // Sadece başarılıysa mesajları yenile
          await _fetchMessages();
        } else {
          // Başarısızsa, hatayı konsola yazdır ve sahte mesajı sil
          debugPrint("Sunucu mesaj göndermeyi reddetti: ${data['message']}");
          if (mounted) setState(() => messages.remove(optimisticMsg));
        }

      } catch (e) {
        debugPrint("Mesaj gönderme hatası (catch): $e");
        if (mounted) setState(() => messages.remove(optimisticMsg));
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
    }

  // --- YARDIMCI FONKSİYONLAR ---

  /// EKLENDİ: Yeni mesaja (listenin en altı) kaydırır
  void _scrollToBottom({bool jump = false}) {
    // Kısa bir gecikme, listenin güncellenmesini bekler
    Timer(const Duration(milliseconds: 100), () {
      if (!mounted || !_scrollController.hasClients) return;

      if (jump) {
        // jump: sayfa ilk açıldığında animasyonsuz atla
        _scrollController.jumpTo(0.0);
      } else {
        // animate: yeni mesaj gönderildiğinde kaydır
        _scrollController.animateTo(
          0.0, // reverse=true olduğu için 0.0 en alttır
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// EKLENDİ: Tarih/saat formatı (Örn: "14:05")
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return "";
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "";
    }
  }

  /// DÜZELTME: Hem Network (http) hem de Asset (assets/) yollarını destekler
  ImageProvider _getAvatarProvider(String? photoPath) {
    final path = photoPath ?? "assets/default_avatar.jpg";
    if (path.startsWith("http")) {
      return NetworkImage(path);
    } else {
      return AssetImage(path);
    }
  }
  // ------------------------------

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose(); // EKLENDİ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              // DÜZELTME: _getAvatarProvider kullanıldı
              backgroundImage: _getAvatarProvider(photoUrl),
              radius: 16,
            ),
            const SizedBox(width: 10),
            Text(username ?? "Sohbet"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : ListView.builder(
              controller: _scrollController, // EKLENDİ
              reverse: true, // En yeni mesajlar en altta
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                // reverse=true olduğu için sondan başa doğru (en yeni mesaj)
                final msg = messages[messages.length - 1 - i];

                // DÜZELTME: ID ile kontrol
                final isMe = msg["user_id"].toString() == userId.toString();

                // DÜZELTME: _getAvatarProvider kullanıldı
                final avatarProvider = _getAvatarProvider(msg["photo_url"]);

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar (sadece başkasıysa solda)
                        if (!isMe)
                          CircleAvatar(radius: 18, backgroundImage: avatarProvider),
                        if (!isMe) const SizedBox(width: 8),

                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.orange[300] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                // Kullanıcı Adı (sadece başkasıysa)
                                if (!isMe)
                                  Text(
                                    msg["username"] ?? "Kullanıcı",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                // Mesaj
                                Text(
                                  msg["message"],
                                  style: const TextStyle(fontSize: 15),
                                ),
                                // EKLENDİ: Tarih/Saat
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(msg["created_at"]),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isMe ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Avatar (sadece bensem sağda)
                        if (isMe) const SizedBox(width: 8),
                        if (isMe)
                          CircleAvatar(radius: 18, backgroundImage: avatarProvider),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Mesaj yazma alanı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Mesaj yaz...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(), // EKLENDİ: Enter ile gönder
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}