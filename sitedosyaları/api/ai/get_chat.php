<?php
require_once "../db.php"; // db.php'yi çağır

$user_id = isset($_GET["user_id"]) ? intval($_GET["user_id"]) : 0;
$session_id = 0;
$allMessages = []; // Boş mesaj listesi

if ($user_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Kullanıcı ID'si eksik."]);
    exit;
}

try {
    // 1. Kullanıcının en son oturumunu bul
    $stmt = $db->prepare("SELECT id FROM ai_sessions WHERE user_id=? ORDER BY id DESC LIMIT 1");
    $stmt->execute([$user_id]);
    $last_session = $stmt->fetch();
    
    if ($last_session) {
        // Oturum varsa, session_id'yi ayarla
        $session_id = intval($last_session['id']);
        
        // ⭐️⭐️⭐️ DOĞRU SORGU BURADA (LIMIT YOK) ⭐️⭐️⭐️
        // O oturumdaki BÜTÜN mesajları SQL'den çek
        $stmt_msg = $db->prepare("SELECT role, message FROM ai_messages WHERE session_id=? ORDER BY id ASC");
        $stmt_msg->execute([$session_id]);
        $allMessages = $stmt_msg->fetchAll(PDO::FETCH_ASSOC);

    } else {
        // 3. Kullanıcının HİÇ oturumu yoksa, yeni bir tane oluştur
        $stmt_new = $db->prepare("INSERT INTO ai_sessions (user_id, title) VALUES (?, 'Yeni Sohbet')");
        $stmt_new->execute([$user_id]);
        $session_id = $db->lastInsertId(); // Yeni oturumun ID'sini al
    }

    // 4. Flutter'a sonucu gönder
    echo json_encode([
        "status" => "ok",
        "session_id" => $session_id, 
        "messages" => $allMessages   // ⭐️ Burası TÜM listeyi gönderir
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "get_chat Hatası: " . $e->getMessage()]);
}