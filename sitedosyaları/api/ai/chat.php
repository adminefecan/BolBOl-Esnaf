<?php
// Bir üst klasördeki db.php dosyasını çağır
require_once "../db.php"; 

// Parametreleri al
$user_id = isset($_GET["user_id"]) ? intval($_GET["user_id"]) : 0;
$message = isset($_GET["message"]) ? trim($_GET["message"]) : "";
$session_id = isset($_GET["session_id"]) ? intval($_GET["session_id"]) : 0;

if ($user_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Kullanıcı ID (user_id) gerekli."]);
    exit;
}

try {
    // 1. Kullanıcı var mı diye bak
    $check = $db->prepare("SELECT id FROM users WHERE id=?");
    $check->execute([$user_id]);
    if (!$check->fetch()) {
        echo json_encode(["status" => "error", "message" => "Kullanıcı bulunamadı."]);
        exit;
    }

    // ----------------------------------------------------------------------
    // 2. ⭐️ İSTEDİĞİN YER BURASI: ESKİ MESAJLARI ÇEKME ⭐️
    // Eğer session_id gelmemişse (0'sa) VE yeni bir mesaj da yoksa
    // (yani sayfa YENİ AÇILMIŞSA), SQL'den en son sohbeti bul.
    // ----------------------------------------------------------------------
    if ($session_id <= 0 && $message === "") {
        $stmt = $db->prepare("SELECT id FROM ai_sessions WHERE user_id=? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$user_id]);
        $last_session = $stmt->fetch();
        if ($last_session) {
            $session_id = intval($last_session['id']); // Bulunan son oturumun ID'sini kullan
        }
    }
    
    // 3. Oturum ID'si hala 0'sa (hiç sohbet etmemişse), YENİ OTURUM oluştur.
    if ($session_id <= 0) {
        $stmt = $db->prepare("INSERT INTO ai_sessions (user_id, title) VALUES (?, 'Yeni Sohbet')");
        $stmt->execute([$user_id]);
        $session_id = $db->lastInsertId(); // Yeni oturumun ID'sini al
    }

    // 4. Yeni mesaj varsa (message doluysa), YAPAY ZEKAYA SOR
    $reply = "";
    if ($message !== "") {
        // Önce kullanıcının mesajını SQL'e kaydet
        $db->prepare("INSERT INTO ai_messages (session_id, role, message, created_at) VALUES (?, 'user', ?, NOW())")
           ->execute([$session_id, $message]);

        // 🔸 Groq API Ayarları
        $url = "https://api.groq.com/openai/v1/chat/completions";
        // 🚨 BU ANAHTARI GÜVENLİ BİR YERE KOYMALISIN 🚨
        $key = "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"; 

        // Son 10 mesajı SQL'den çek (yapay zeka hafızası için)
        $stmt = $db->prepare("SELECT role, message FROM ai_messages WHERE session_id=? ORDER BY id DESC LIMIT 10");
        $stmt->execute([$session_id]);
        $history = array_reverse($stmt->fetchAll(PDO::FETCH_ASSOC)); // Eskiden yeniye sırala

        $messages_payload = [];
        foreach ($history as $h) {
            $messages_payload[] = ["role" => $h["role"], "content" => $h["message"]];
        }

        $payload = [
            "model" => "openai/gpt-oss-20b", // Hızlı bir model
            "messages" => $messages_payload,
            "temperature" => 0.7,
            "max_tokens" => 1024,
            "stream" => false
        ];

        // API'ye isteği gönder
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => ["Content-Type: application/json", "Authorization: Bearer $key"],
            CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_TIMEOUT => 90
        ]);
        $response = curl_exec($ch);
        $error = curl_error($ch);
        curl_close($ch);

        if ($error) {
            echo json_encode(["status" => "error", "message" => "API hatası: $error"]);
            exit;
        }

        $res = json_decode($response, true);
        $reply = $res["choices"][0]["message"]["content"] ?? "Yanıt alınamadı.";

        // Yapay zeka yanıtını SQL'e kaydet
        $db->prepare("INSERT INTO ai_messages (session_id, role, message, created_at) VALUES (?, 'assistant', ?, NOW())")
           ->execute([$session_id, $reply]);
    }

    // 5. ⭐️ SONUÇ: O anki oturumdaki BÜTÜN MESAJLARI SQL'den çek
    // (Sayfa yeni de açılsa, yeni mesaj da atılsa burası çalışır)
    $stmt = $db->prepare("SELECT role, message FROM ai_messages WHERE session_id=? ORDER BY id ASC");
    $stmt->execute([$session_id]);
    $allMessages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 6. Flutter'a JSON olarak gönder
    echo json_encode([
        "status" => "ok",
        "session_id" => $session_id, // Flutter'ın oturum ID'sini bilmesi için
        "messages" => $allMessages   // Flutter'ın listeyi doldurması için tüm mesajlar
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}