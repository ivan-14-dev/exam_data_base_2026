<?php
// Shared bootstrap: configuration, PDO connection, secure session, CSRF and output helpers.
declare(strict_types=1);

$config = require __DIR__ . '/../config/config.php';

// ---------------------------------------------------------------------
// HTTP security headers
// ---------------------------------------------------------------------
header("Content-Security-Policy: default-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; frame-ancestors 'none'; form-action 'self'");
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('Referrer-Policy: same-origin');

// ---------------------------------------------------------------------
// Secure session (HttpOnly + SameSite cookie, strict mode, idle timeout)
// ---------------------------------------------------------------------
$isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');
ini_set('session.use_strict_mode', '1');
ini_set('session.use_only_cookies', '1');
session_name('ICTUSESSID');
session_set_cookie_params([
    'lifetime' => 0,
    'path'     => '/',
    'secure'   => $isHttps,
    'httponly' => true,
    'samesite' => 'Strict',
]);
session_start();

if (isset($_SESSION['last_activity']) && time() - $_SESSION['last_activity'] > $config['session_idle_timeout']) {
    $_SESSION = [];
    session_regenerate_id(true);
}
$_SESSION['last_activity'] = time();

// ---------------------------------------------------------------------
// Database connection (PDO with real server-side prepared statements)
// ---------------------------------------------------------------------
function db(): PDO
{
    static $pdo = null;
    global $config;

    if ($pdo === null) {
        $c = $config['db'];
        if ($c['pass'] === false) {
            throw new RuntimeException('DB_PASS environment variable is not set.');
        }
        $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=%s', $c['host'], $c['port'], $c['name'], $c['charset']);
        $pdo = new PDO($dsn, $c['user'], $c['pass'], [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,  // parameters are sent separately from the SQL text
        ]);
    }
    return $pdo;
}

// ---------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------
function e(string|int|float|null $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function money(string|float $amount): string
{
    return number_format((float) $amount, 0, '.', ' ') . ' FCFA';
}

function redirect(string $path): never
{
    header('Location: ' . $path);
    exit;
}

function flash(?string $message = null, string $type = 'success'): ?array
{
    if ($message !== null) {
        $_SESSION['flash'] = ['message' => $message, 'type' => $type];
        return null;
    }
    $f = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    return $f;
}

function csrf_token(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="csrf_token" value="' . e(csrf_token()) . '">';
}

function csrf_verify(): void
{
    $sent = $_POST['csrf_token'] ?? '';
    if (!is_string($sent) || !hash_equals(csrf_token(), $sent)) {
        http_response_code(400);
        exit('Invalid or expired form. Please go back and try again.');
    }
}

function current_user(): ?array
{
    return $_SESSION['user'] ?? null;
}

function require_login(): array
{
    $user = current_user();
    if ($user === null) {
        flash('Please log in to book tickets.', 'info');
        redirect('login.php');
    }
    return $user;
}

function render_header(string $title): void
{
    $user = current_user();
    require __DIR__ . '/../templates/header.php';
}

function render_footer(): void
{
    require __DIR__ . '/../templates/footer.php';
}
