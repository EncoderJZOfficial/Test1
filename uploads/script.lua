<?php
// ===== НАСТРОЙКИ =====
$GITHUB_TOKEN = "github_pat_НОВЫЙ_ТОКЕН";       // ← вставьте
$API_KEY      = "СЛУЧАЙНАЯ_СТРОКА_32_СИМВОЛА";  // ← придумайте
$ALLOWED_REPO = "EncoderJZOfficial/Test1";
// =====================

ini_set('display_errors', 0);
error_reporting(0);
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

if (($_POST['key'] ?? '') !== $API_KEY) {
    http_response_code(403);
    echo json_encode(["error" => "bad key"]);
    exit;
}

$repo    = $_POST['repo']    ?? $ALLOWED_REPO;
$path    = $_POST['path']    ?? '';
$content = $_POST['content'] ?? '';
$message = $_POST['message'] ?? 'upload via GG';

if ($repo !== $ALLOWED_REPO) {
    http_response_code(403);
    echo json_encode(["error" => "repo not allowed"]);
    exit;
}

if ($path === '' || $content === '') {
    http_response_code(400);
    echo json_encode(["error" => "path/content required"]);
    exit;
}

$api = "https://api.github.com/repos/$repo/contents/$path";

// 1) узнать sha, если файл существует
$ch = curl_init($api);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 15,
    CURLOPT_HTTPHEADER     => [
        "Authorization: token $GITHUB_TOKEN",
        "User-Agent: GG-Uploader"
    ]
]);
$resp = json_decode(curl_exec($ch), true);
$sha  = $resp['sha'] ?? null;
curl_close($ch);

// 2) PUT — создать/обновить
$data = [
    "message" => $message,
    "content" => $content
];
if ($sha) $data['sha'] = $sha;

$ch = curl_init($api);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CUSTOMREQUEST  => "PUT",
    CURLOPT_POSTFIELDS     => json_encode($data),
    CURLOPT_TIMEOUT        => 20,
    CURLOPT_HTTPHEADER     => [
        "Authorization: token $GITHUB_TOKEN",
        "User-Agent: GG-Uploader",
        "Content-Type: application/json"
    ]
]);
$result = curl_exec($ch);
$code   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

http_response_code($code);
echo json_encode([
    "code" => $code,
    "resp" => json_decode($result, true)
]);