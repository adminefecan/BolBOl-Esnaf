<?php
// Hata raporlamayı aç
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=utf-8");
mb_internal_encoding("UTF-8");

/**
 * DÜZELTME: 
 * 'send_message.php' dosyasındaki gibi, 'db.php' hatalarını
 * yakalamak için 'Throwable' ve 'isset($db)' kontrolleri eklendi.
 */
try {
    // Veritabanı bağlantısını da try içine al
    require 'db.php'; 
    
    // $db değişkeni 'db.php' dosyasından gelmeli.
    if (!isset($db) || $db === null) {
         echo json_encode(["status" => "error", "message" => "'get_messages.php', 'db.php' dosyasından geçerli bir \$db değişkeni alamadı."]);
         exit;
    }
    
    // Flutter'da "isMe" kontrolü için 'm.user_id' eklendi
    // Sohbet mantığı için 'ORDER BY ASC' (eskiden yeniye)
    $stmt = $db->query("
        SELECT m.id, m.user_id, m.message, m.created_at, u.username, u.photo_url
        FROM messages m
        JOIN users u ON u.id = m.user_id
        ORDER BY m.created_at ASC 
        LIMIT 50
    ");

    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Başarılı yanıt
    echo json_encode(["status" => "success", "messages" => $messages]);

} catch (Throwable $e) { // 'Throwable' (PHP 7+) tüm hataları yakalar
    // 'db.php' bağlantı hatası veya herhangi bir PHP hatası
    http_response_code(500); // Sunucu hatası kodu gönder
    echo json_encode([
        "status" => "error", 
        "message" => "Sunucu taraflı PHP hatası (get_messages.php): " . $e->getMessage(),
        "file" => $e->getFile(),
        "line" => $e->getLine()
    ]);
}
?>