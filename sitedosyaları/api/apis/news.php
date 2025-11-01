<?php
header("Content-Type: application/json; charset=UTF-8");

$query = $_GET['q'] ?? 'türkiye';
$apiKey = "2123e3dd53mshbd1eb79c8751335p1687a5jsne4518b947968";

$url = "https://real-time-web-search.p.rapidapi.com/search?q=" . urlencode($query) . "&num=10&start=0&gl=tr&hl=tr&device=desktop";

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        "x-rapidapi-host: real-time-web-search.p.rapidapi.com",
        "x-rapidapi-key: $apiKey"
    ]
]);

$response = curl_exec($ch);
curl_close($ch);

if (!$response) {
    echo json_encode(["error" => "API bağlantı hatası"]);
    exit;
}

$data = json_decode($response, true);

// 🔹 Yeni JSON yapısına göre kontrol
$results = $data['data']['organic_results'] ?? [];

if (empty($results)) {
    echo json_encode([
        "error" => "Haber bulunamadı",
        "details" => $data
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

// 🔹 Organik sonuçları haber formatına çevir
$haberler = [];
foreach ($results as $item) {
    $haberler[] = [
        "title" => $item["title"] ?? "Başlık Yok",
        "desc" => $item["snippet"] ?? "Açıklama bulunamadı.",
        "url" => $item["url"] ?? "",
        "image" => null, // Bu API resim döndürmüyor
        "source" => $item["displayed_link"] ?? ($item["source"] ?? "Bilinmiyor"),
        "published" => $item["date"] ?? ""
    ];
}

echo json_encode(["articles" => $haberler], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>
