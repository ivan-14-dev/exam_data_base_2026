<?php
// Application configuration. Secrets come from environment variables, never from source code.
declare(strict_types=1);

return [
    'db' => [
        'host'    => getenv('DB_HOST') ?: '127.0.0.1',
        'port'    => (int) (getenv('DB_PORT') ?: 3306),
        'name'    => getenv('DB_NAME') ?: 'ictu_events',
        'user'    => getenv('DB_USER') ?: 'ictu_app',
        'pass'    => getenv('DB_PASS'),
        'charset' => 'utf8mb4',
    ],
    'session_idle_timeout' => 1800,   // seconds
    'max_login_attempts'   => 5,
    'lockout_minutes'      => 15,
    'max_seats_per_booking' => 10,
];
