<?php
// ----------------------
// 🧠 Yönlendirme deliliğine tam çözüm
// ----------------------
file_put_contents(__DIR__."/debug_username.txt", json_encode($_POST)."\n", FILE_APPEND);
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Flutter preflight
if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    echo json_encode(["status" => "ok"]);
    exit;
}

// GET bile gelse POST gibi işlenir
$method = $_SERVER["REQUEST_METHOD"];
if ($method !== "POST" && $method !== "GET") {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek"]);
    exit;
}

// Hem $_POST hem $_GET'i tekleştir
$input = array_merge($_GET, $_POST);

// Kullanıcı adı kontrolü
$username = isset($input["username"]) ? trim($input["username"]) : "";
if ($username === "") {
    echo json_encode(["status" => "error", "message" => "Kullanıcı adı boş olamaz."]);
    exit;
}

// MySQL bağlantısı
$host = "localhost";
$dbname = "efecandc_bolbol";   // kendi veritabanın
$user = "efecandc_bolbol";
$pass = "Efecan755.";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Veritabanı hatası: ".$e->getMessage()]);
    exit;
}

// Fotoğraf yükleme (isteğe bağlı)
$photo_url = "https://bolbolesnaf.efecand.com.tr/api/uploads/default_avatar.jpg";
if (isset($_FILES["photo"]) && $_FILES["photo"]["error"] === UPLOAD_ERR_OK) {
    $upload_dir = __DIR__ . "/uploads/";
    if (!is_dir($upload_dir)) mkdir($upload_dir, 0777, true);

    $filename = time() . "_" . basename($_FILES["photo"]["name"]);
    $target = $upload_dir . $filename;
    if (move_uploaded_file($_FILES["photo"]["tmp_name"], $target)) {
        $photo_url = "https://bolbolesnaf.efecand.com.tr/api/uploads/" . $filename;
    }
}

// Aynı kullanıcı var mı kontrol et
$stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
$stmt->execute([$username]);
$existing = $stmt->fetch(PDO::FETCH_ASSOC);

if ($existing) {
    echo json_encode([
        "status" => "exists",
        "user" => [
            "id" => $existing["id"],
            "username" => $existing["username"],
            "photo_url" => $existing["photo_url"]
        ]
    ]);
    exit;
}

// Yeni kullanıcı kaydı
$stmt = $pdo->prepare("INSERT INTO users (username, photo_url) VALUES (?, ?)");
$stmt->execute([$username, $photo_url]);
$newId = $pdo->lastInsertId();

echo json_encode([
    "status" => "success",
    "user" => [
        "id" => $newId,
        "username" => $username,
        "photo_url" => $photo_url
    ]
]);
?>
