<?php
$host = "localhost";
$user = "efecandc_bolbol";
$pass = "Efecan755.";
$dbname = "efecandc_bolbol";
$charset = "utf8mb4";

$dsn = "mysql:host=$host;dbname=$dbname;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $db = new PDO($dsn, $user, $pass, $options);
    return $db; // 🔥 require çağrılarında döner
} catch (PDOException $e) {
    header("Content-Type: application/json; charset=utf-8");
    echo json_encode([
        "status" => "error",
        "message" => "Veritabanı bağlantı hatası",
        "details" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
?>
