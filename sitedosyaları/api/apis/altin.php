<?php
header("Content-Type: application/json; charset=UTF-8");

// Güvenlik: istenirse referer/ip filtre eklenir
$sourceUrl = "https://finans.truncgil.com/today.json";

$response = @file_get_contents($sourceUrl);
if ($response === false) {
    http_response_code(502);
    echo json_encode(["error" => "Kaynak erişilemedi."]);
    exit;
}

// Opsiyonel: basit temizleme / dönüştürme
$data = json_decode($response, true);
if ($data === null) {
    echo json_encode(["error" => "Geçersiz JSON geldi."]);
    exit;
}

echo json_encode([
    "kaynak" => "truncgil",
    "tarih" => date("Y-m-d H:i:s"),
    "veri" => $data
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
