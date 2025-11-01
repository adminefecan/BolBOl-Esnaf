<?php
header('Content-Type: application/json');
$data = json_decode(file_get_contents("php://input"), true);
$email = $data["email"] ?? null;

if (!$email) {
    echo json_encode(["error" => "Email adresi gerekli"]);
    exit;
}

$key = getenv('RAPIDAPI_KEY') ?: "2123e3dd53mshbd1eb79c8751335p1687a5jsne4518b947968";
$host = getenv('RAPIDAPI_EMAIL_HOST') ?: "gmailnator.p.rapidapi.com";

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "https://$host/inbox",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => [
        "Content-Type: application/json",
        "x-rapidapi-host: $host",
        "x-rapidapi-key: $key"
    ],
    CURLOPT_POSTFIELDS => json_encode(["email" => $email, "limit" => 10])
]);

$response = curl_exec($curl);
curl_close($curl);
echo $response;
?>
