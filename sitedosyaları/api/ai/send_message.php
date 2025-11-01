<?php
require_once "../db.php"; 

error_reporting(E_ALL);
ini_set('display_errors', 1);

$user_id = isset($_GET["user_id"]) ? intval($_GET["user_id"]) : 0;
$message = isset($_GET["message"]) ? trim($_GET["message"]) : "";
$session_id = isset($_GET["session_id"]) ? intval($_GET["session_id"]) : 0;

if ($user_id <= 0 || $session_id <= 0 || $message === "") {
    echo json_encode(["status" => "error", "message" => "Eksik parametreler."]);
    exit;
}

try {
    // 1. Kullanıcının mesajını SQL'e yaz
    $db->prepare("INSERT INTO ai_messages (session_id, role, message, created_at) VALUES (?, 'user', ?, NOW())")
       ->execute([$session_id, $message]);

    // 2. Groq API'ye bağlan
    $url = "https://api.groq.com/openai/v1/chat/completions";
    $key = "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"; 

    // ⭐️ BU, SADECE AI HAFIZASI İÇİN (LIMIT 10 OLMASI NORMAL)
    $stmt = $db->prepare("SELECT role, message FROM ai_messages WHERE session_id=? ORDER BY id DESC LIMIT 10");
    $stmt->execute([$session_id]);
    $history = array_reverse($stmt->fetchAll(PDO::FETCH_ASSOC)); 

    $messages_payload = [];
    foreach ($history as $h) {
        $messages_payload[] = ["role" => $h["role"], "content" => $h["message"]];
    }

    $payload = [
        "model" => "openai/gpt-oss-20b",
        "messages" => $messages_payload,
        "temperature" => 0.7,
        "max_tokens" => 1024,
        "stream" => false
    ];

    // 3. API'ye isteği gönder (cURL)
    $ch = curl_init($url);
    if (!function_exists('curl_init')) {
        throw new Exception("Sunucuda cURL eklentisi yüklü değil.");
    }
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

    if ($error) throw new Exception("cURL API Hatası: $error");
    $res = json_decode($response, true);
    if (isset($res["error"])) throw new Exception("Groq API Hatası: " . $res["error"]["message"]);
    
    $reply = $res["choices"][0]["message"]["content"] ?? "Yanıt alınamadı.";

    // 4. Yapay zeka yanıtını SQL'e yaz
    $db->prepare("INSERT INTO ai_messages (session_id, role, message, created_at) VALUES (?, 'assistant', ?, NOW())")
       ->execute([$session_id, $reply]);

    // 5. ⭐️⭐️ ÖNEMLİ KISIM BURASI ⭐️⭐️⭐️
    // Flutter'a GÖNDERMEK için BÜTÜN mesajları tekrar çek (LIMIT YOK!)
    $stmt_all = $db->prepare("SELECT role, message FROM ai_messages WHERE session_id=? ORDER BY id ASC");
    $stmt_all->execute([$session_id]);
    $allMessages = $stmt_all->fetchAll(PDO::FETCH_ASSOC);

    // 6. Flutter'a TAM listeyi gönder
    echo json_encode([
        "status" => "ok",
        "session_id" => $session_id,
        "messages" => $allMessages // ⭐️ Burası TÜM listeyi gönderir
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "send_message.php ÇÖKTÜ: " . $e->getMessage(), "line" => $e->getLine()]);
}