<?php
require_once "../db.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");

$session_id = intval($_GET["session_id"] ?? 0);
if ($session_id <= 0) {
    echo json_encode([]);
    exit;
}

$stmt = $db->prepare("SELECT role, message, created_at FROM ai_messages WHERE session_id=? ORDER BY id ASC");
$stmt->execute([$session_id]);
$messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode($messages, JSON_UNESCAPED_UNICODE);
?>
