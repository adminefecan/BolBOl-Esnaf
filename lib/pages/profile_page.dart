import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  bool isLoading = false;
  bool _isEditing = false;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Mevcut kullanıcıyı yükler
  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    final existingUsername = prefs.getString("username");
    final existingPhoto = prefs.getString("photo_url");

    if (existingUsername != null && existingUsername.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isEditing = true;
          _nameController.text = existingUsername;
          _existingPhotoUrl = existingPhoto;
        });
      }
    }
  }

  /// Galeriden fotoğraf seç
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  /// Profil oluştur veya düzenle
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir kullanıcı adı girin")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔸 cache'i kırmak için unique parametre
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final uri = Uri.parse(
        "https://bolbolesnaf.efecand.com.tr/api/chat/register_user.php?username=$name&_t=$timestamp",
      );

      final res = await http.get(
        uri,
        headers: {
          "Cache-Control": "no-cache, no-store, must-revalidate",
          "Pragma": "no-cache",
          "Expires": "0",
          "Accept": "application/json",
        },
      );

      debugPrint("🛰️ Status: ${res.statusCode}");
      debugPrint("📦 Body: ${res.body}");

      if (!mounted) return;
      setState(() => isLoading = false);
      if (!mounted) return;

      if (res.statusCode != 200 || !res.body.trim().startsWith("{")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sunucudan geçersiz yanıt: ${res.body}")),
        );
        return;
      }

      final data = jsonDecode(res.body);

      if (data["status"] == "success" ||
          data["status"] == "exists" ||
          data["status"] == "created") {
        final user = data["user"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("user_id", int.parse(user["id"].toString()));
        await prefs.setString("username", user["username"]);
        await prefs.setString(
          "photo_url",
          (user["photo_url"]?.toString().isNotEmpty ?? false)
              ? user["photo_url"]
              : "assets/default_avatar.jpg",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil kaydedildi ✅")),
        );

        if (!mounted) return;
        if (_isEditing) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${data['message']}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İşlem hatası: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    ImageProvider<Object> profileImageProvider;

    if (_selectedImage != null) {
      profileImageProvider = FileImage(_selectedImage!);
    } else if (_existingPhotoUrl != null &&
        _existingPhotoUrl!.startsWith("http")) {
      profileImageProvider = NetworkImage(_existingPhotoUrl!);
    } else if (_existingPhotoUrl != null) {
      profileImageProvider = AssetImage(_existingPhotoUrl!);
    } else {
      profileImageProvider = const AssetImage("assets/default_avatar.jpg");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Profili Düzenle" : "Profil Oluştur"),
        automaticallyImplyLeading: _isEditing,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: profileImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.edit,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Kullanıcı Adı",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: isLoading ? null : _saveProfile,
              icon: const Icon(Icons.save),
              label: Text(isLoading ? "Kaydediliyor..." : "Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
