<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Preflight (OPTIONS)
if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    echo json_encode(["status" => "ok"]);
    exit;
}

// GET veya POST'tan veriyi al
$input = array_merge($_GET, $_POST);
$username = isset($input["username"]) ? trim($input["username"]) : "";
$new_username = isset($input["new_username"]) ? trim($input["new_username"]) : "";
$photo_updated = false;

if ($username === "" && $new_username === "") {
    echo json_encode(["status" => "error", "message" => "Kullanıcı adı boş olamaz."]);
    exit;
}

// DB bağlantısı
$host = "localhost";
$dbname = "efecandc_bolbol";
$user = "efecandc_bolbol";
$pass = "Efecan755.";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Veritabanı hatası: ".$e->getMessage()]);
    exit;
}

// Fotoğraf yükleme
$photo_url = null;
if (isset($_FILES["photo"]) && $_FILES["photo"]["error"] === UPLOAD_ERR_OK) {
    $upload_dir = __DIR__ . "/uploads/";
    if (!is_dir($upload_dir)) mkdir($upload_dir, 0777, true);
    $filename = time() . "_" . basename($_FILES["photo"]["name"]);
    $target = $upload_dir . $filename;
    if (move_uploaded_file($_FILES["photo"]["tmp_name"], $target)) {
        $photo_url = "https://bolbolesnaf.efecand.com.tr/api/uploads/" . $filename;
        $photo_updated = true;
    }
}

// Kullanıcı var mı kontrol et
$stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
$stmt->execute([$username]);
$userData = $stmt->fetch(PDO::FETCH_ASSOC);

if ($userData) {
    // 🔸 Kullanıcı varsa güncelle
    $updateSql = "UPDATE users SET ";
    $params = [];
    if ($new_username !== "") {
        $updateSql .= "username = ?, ";
        $params[] = $new_username;
    }
    if ($photo_updated) {
        $updateSql .= "photo_url = ?, ";
        $params[] = $photo_url;
    }
    $updateSql = rtrim($updateSql, ", ");
    $updateSql .= " WHERE id = ?";
    $params[] = $userData["id"];

    if (!empty($params)) {
        $stmt = $pdo->prepare($updateSql);
        $stmt->execute($params);
    }

    // Güncel bilgiyi döndür
    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$userData["id"]]);
    $updated = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "updated", "user" => $updated]);
    exit;
} else {
    // 🔸 Yoksa yeni ekle
    if ($photo_url === null)
        $photo_url = "https://bolbolesnaf.efecand.com.tr/api/uploads/default_avatar.jpg";
    $stmt = $pdo->prepare("INSERT INTO users (username, photo_url) VALUES (?, ?)");
    $stmt->execute([$new_username ?: $username, $photo_url]);
    $id = $pdo->lastInsertId();

    echo json_encode([
        "status" => "created",
        "user" => ["id" => $id, "username" => $new_username ?: $username, "photo_url" => $photo_url]
    ]);
    exit;
}
