<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");

// Form verilerini hem GET hem POST'tan al
$old = isset($_REQUEST["old_username"]) ? trim($_REQUEST["old_username"]) : "";
$new = isset($_REQUEST["new_username"]) ? trim($_REQUEST["new_username"]) : "";

// Hata kontrolü
if ($old === "" && !isset($_FILES["photo"])) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre."]);
    exit;
}

// Veritabanı bağlantısı
$host = "localhost";
$dbname = "efecandc_bolbol";
$user = "efecandc_bolbol";
$pass = "Efecan755.";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    exit;
}

// Kullanıcı kontrolü
$stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
$stmt->execute([$old]);
$userData = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$userData) {
    echo json_encode(["status" => "error", "message" => "Kullanıcı bulunamadı."]);
    exit;
}

// Fotoğraf yüklendiyse işle
$photo_url = $userData["photo_url"]; // mevcut fotoğrafı koru
if (isset($_FILES["photo"]) && $_FILES["photo"]["error"] === UPLOAD_ERR_OK) {
    $upload_dir = __DIR__ . "/uploads/";
    if (!is_dir($upload_dir)) mkdir($upload_dir, 0777, true);

    $filename = time() . "_" . basename($_FILES["photo"]["name"]);
    $target = $upload_dir . $filename;

    if (move_uploaded_file($_FILES["photo"]["tmp_name"], $target)) {
        $photo_url = "https://bolbolesnaf.efecand.com.tr/api/uploads/" . $filename;
    }
}

// Güncelleme sorgusu oluştur
$updateSql = "UPDATE users SET ";
$params = [];
if ($new !== "") {
    $updateSql .= "username = ?, ";
    $params[] = $new;
}
if (isset($_FILES["photo"]) && $_FILES["photo"]["error"] === UPLOAD_ERR_OK) {
    $updateSql .= "photo_url = ?, ";
    $params[] = $photo_url;
}
$updateSql = rtrim($updateSql, ", ");
$updateSql .= " WHERE id = ?";
$params[] = $userData["id"];

$stmt = $pdo->prepare($updateSql);
$stmt->execute($params);

// Son güncel veriyi döndür
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$userData["id"]]);
$updated = $stmt->fetch(PDO::FETCH_ASSOC);

echo json_encode(["status" => "updated", "user" => $updated]);
