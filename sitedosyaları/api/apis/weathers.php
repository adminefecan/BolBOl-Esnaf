<?php
header("Content-Type: application/json; charset=UTF-8");

$city = $_GET['city'] ?? 'Istanbul';
$apiKey = "2123e3dd53mshbd1eb79c8751335p1687a5jsne4518b947968"; // senin RapidAPI key'in

$url = "https://weatherapi-com.p.rapidapi.com/current.json?q=" . urlencode($city);

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        "x-rapidapi-host: weatherapi-com.p.rapidapi.com",
        "x-rapidapi-key: $apiKey"
    ],
    CURLOPT_SSL_VERIFYPEER => false
]);

$response = curl_exec($ch);
curl_close($ch);

if (!$response) {
    echo json_encode(["error" => "API bağlantı hatası"]);
    exit;
}

$data = json_decode($response, true);

if (!isset($data['current'])) {
    echo json_encode(["error" => "Şehir bulunamadı", "details" => $data]);
    exit;
}

echo json_encode([
    "city" => $data['location']['name'],
    "temp" => $data['current']['temp_c'],
    "desc" => $data['current']['condition']['text'],
    "icon" => $data['current']['condition']['icon']
]);
?>
