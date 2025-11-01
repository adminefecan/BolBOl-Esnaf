<?php
header("Content-Type: application/json; charset=UTF-8");

$symbol = $_GET['symbol'] ?? 'BTC';
$symbol = strtoupper($symbol);

$url = "https://api.coingecko.com/api/v3/simple/price?ids=$symbol&vs_currencies=usd,eur,try";

$response = file_get_contents($url);
if (!$response) {
    echo json_encode(["error" => "API bağlantı hatası."]);
    exit;
}

$data = json_decode($response, true);
if (!isset($data[strtolower($symbol)])) {
    echo json_encode(["error" => "Kripto bulunamadı."]);
    exit;
}

echo json_encode([
    "symbol" => $symbol,
    "prices" => $data[strtolower($symbol)]
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>
