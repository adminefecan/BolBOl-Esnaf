<?php
header('Content-Type: application/json');
$action = $_GET['action'] ?? '';

switch ($action) {
    case 'create_email':
        require 'apis/email_generator.php';
        break;

    case 'get_inbox':
        require 'apis/email_inbox.php';
        break;

    default:
        echo json_encode(["error" => "Geçersiz istek"]);
        break;
}
?>
