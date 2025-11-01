<?php
// Hata raporlamayı aç (hatayı görebilmemiz için)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Header'ları her zaman en başa koyun
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=utf-8");
mb_internal_encoding("UTF-8");

/**
 * DÜZELTME: 
 * 1. 'require' işlemini try bloğuna aldık.
 * 2. 'catch' bloğunu 'PDOException' yerine 'Throwable' yaptık.
 * Bu, 'db.php' dosyasındaki bağlantı hatası, syntax hatası gibi
 * TÜM PHP hatalarını yakalayacaktır.
 */
try {
    // Veritabanı bağlantısını da try içine al
    require 'db.php'; 

    $data = json_decode(file_get_contents("php://input"), true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        echo json_encode(["status" => "error", "message" => "Geçersiz JSON formatı."]);
        exit;
    }

    $userId = intval($data["user_id"] ?? 0);
    $message = trim($data["message"] ?? "");

    if ($userId <= 0 || $message == "") {
        echo json_encode(["status" => "error", "message" => "Eksik veri: user_id veya message boş"]);
        exit;
    }

    // $db değişkeni 'db.php' dosyasından gelmeli.
    if (!isset($db) || $db === null) {
         echo json_encode(["status" => "error", "message" => "'db.php' dosyasından geçerli bir \$db değişkeni gelmedi."]);
         exit;
    }

    $stmt = $db->prepare("INSERT INTO messages (user_id, message) VALUES (?, ?)");

    if ($stmt === false) {
         echo json_encode([
            "status" => "error", 
            "message" => "SQL prepare hatası: " . $db->errorInfo()[2] 
         ]);
         exit;
    }

    $ok = $stmt->execute([$userId, $message]);

    if ($ok) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode([
            "status" => "error", 
            "message" => "SQL execute hatası: " . $stmt->errorInfo()[2] 
        ]);
    }

} catch (Throwable $e) { // 'Throwable' (PHP 7+) tüm hataları yakalar
    // 'db.php' bağlantı hatası veya herhangi bir PHP hatası (Fatal Error vb.)
    http_response_code(500); // Sunucu hatası kodu gönder
    echo json_encode([
        "status" => "error", 
        "message" => "Sunucu taraflı PHP hatası: " . $e->getMessage(),
        "file" => $e->getFile(), // Hatanın hangi dosyada
        "line" => $e->getLine()  // Hatanın hangi satırda olduğunu göster
    ]);
}
?>