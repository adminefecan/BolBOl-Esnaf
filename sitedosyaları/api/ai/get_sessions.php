<?php
require_once "../db.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");

$user_id = intval($_GET["user_id"] ?? 0);
if ($user_id <= 0) {
    echo json_encode([]);
    exit;
}

$stmt = $db->prepare("SELECT id, title, created_at, updated_at FROM ai_sessions WHERE user_id=? ORDER BY updated_at DESC, created_at DESC");
$stmt->execute([$user_id]);
$sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode($sessions, JSON_UNESCAPED_UNICODE);
?>
