<?php
// ⬇️ BU BİLGİLERİ KONTROL ET ⬇️
$host = 'localhost';
$dbname = 'efecandc_bolbol'; // Burayı doldur
$username = 'efecandc_bolbol';   // Burayı doldur
$password = 'Efecan755.';          // Burayı doldur
// ⬆️ BU BİLGİLERİ KONTROL ET ⬆️

// Hata raporlamayı en üst seviyeye çıkar
error_reporting(E_ALL);
ini_set('display_errors', 1);

// JSON header'ları
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *"); 

$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
     $db = new PDO($dsn, $username, $password, $options);
     
     // InnoDB tablolarının 'autocommit' (otomatik kalıcı kayıt)
     // yapmasını zorunlu hale getir.
     $db->setAttribute(PDO::ATTR_AUTOCOMMIT, 1);
     
} catch (\PDOException $e) {
     echo json_encode([
         "status" => "error", 
         "message" => "MySQL Bağlantı Hatası: " . $e->getMessage() 
     ]);
     exit;
}