<?php
// Log out: POST + CSRF only, destroys the server session and the session cookie.
declare(strict_types=1);
require __DIR__ . '/../src/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit('Method not allowed');
}
csrf_verify();

$_SESSION = [];
$p = session_get_cookie_params();
setcookie(session_name(), '', [
    'expires'  => time() - 3600,
    'path'     => $p['path'],
    'secure'   => $p['secure'],
    'httponly' => $p['httponly'],
    'samesite' => $p['samesite'],
]);
session_destroy();

header('Location: index.php');
exit;
