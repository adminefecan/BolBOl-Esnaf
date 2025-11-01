<?php
header("Content-Type: application/json; charset=UTF-8");

$text = $_GET['text'] ?? '';
$to = $_GET['to'] ?? 'en';
$from = $_GET['from'] ?? 'tr'; // otomatik olarak Türkçe varsayıyoruz

if (empty($text)) {
    echo json_encode(["error" => "Metin girilmedi."]);
    exit;
}

$url = "https://api.mymemory.translated.net/get?q=" . urlencode($text) . "&langpair=$from|$to";

$response = file_get_contents($url);
if (!$response) {
    echo json_encode(["error" => "API bağlantı hatası"]);
    exit;
}

$data = json_decode($response, true);

if (!isset($data['responseData']['translatedText'])) {
    echo json_encode([
        "error" => "Çeviri başarısız.",
        "details" => $data
    ]);
    exit;
}

echo json_encode([
    "text" => $text,
    "translated" => $data['responseData']['translatedText'],
    "from" => $from,
    "to" => $to
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>
