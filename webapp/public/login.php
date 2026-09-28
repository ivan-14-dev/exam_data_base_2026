<?php
// Part 5 Q3 - Secure login (bcrypt verification, account lockout, session fixation protection).
declare(strict_types=1);
require __DIR__ . '/../src/bootstrap.php';

if (current_user()) {
    redirect('index.php');
}

$error = null;
$email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_verify();

    // Step 1: read the credentials
    $email    = mb_strtolower(trim((string) ($_POST['email'] ?? '')));
    $password = (string) ($_POST['password'] ?? '');

    // Step 2: fetch the account with a prepared statement
    $stmt = db()->prepare(
        'SELECT u.user_id, u.attendee_id, u.email, u.password_hash, u.role,
                (u.locked_until IS NOT NULL AND u.locked_until > NOW()) AS is_locked,
                a.first_name, a.last_name
         FROM users u
         LEFT JOIN attendees a ON a.attendee_id = u.attendee_id
         WHERE u.email = :email'
    );
    $stmt->execute([':email' => $email]);
    $account = $stmt->fetch() ?: null;

    if ($account && $account['is_locked']) {
        $error = 'Too many failed attempts. This account is locked for a few minutes.';
    } else {
        // Step 3: always run password_verify (even for unknown e-mails) so response time
        //         does not reveal which e-mails are registered
        $hash  = $account['password_hash'] ?? password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT);
        $valid = password_verify($password, $hash) && $account !== null;

        if ($valid) {
            // Step 4a: success - reset counters, upgrade hash if the algorithm changed
            $upd = db()->prepare('UPDATE users SET failed_attempts = 0, locked_until = NULL, last_login_at = NOW() WHERE user_id = :id');
            $upd->execute([':id' => $account['user_id']]);

            if (password_needs_rehash($hash, PASSWORD_DEFAULT)) {
                $re = db()->prepare('UPDATE users SET password_hash = :h WHERE user_id = :id');
                $re->execute([':h' => password_hash($password, PASSWORD_DEFAULT), ':id' => $account['user_id']]);
            }

            // Step 4b: new session id after login prevents session fixation
            session_regenerate_id(true);
            $_SESSION['user'] = [
                'user_id'     => (int) $account['user_id'],
                'attendee_id' => (int) $account['attendee_id'],
                'email'       => $account['email'],
                'role'        => $account['role'],
                'first_name'  => $account['first_name'],
                'last_name'   => $account['last_name'],
            ];
            unset($_SESSION['csrf_token']);
            flash('Welcome back, ' . $account['first_name'] . '!');
            redirect('book.php');
        }

        // Step 4c: failure - count the attempt and lock after N failures
        if ($account) {
            $fail = db()->prepare(
                'UPDATE users
                 SET locked_until    = IF(failed_attempts + 1 >= :max1, NOW() + INTERVAL :mins MINUTE, locked_until),
                     failed_attempts = IF(failed_attempts + 1 >= :max2, 0, failed_attempts + 1)
                 WHERE user_id = :id'
            );
            $fail->execute([
                ':max1' => $config['max_login_attempts'],
                ':max2' => $config['max_login_attempts'],
                ':mins' => $config['lockout_minutes'],
                ':id'   => $account['user_id'],
            ]);
        }
        // Same generic message whether the e-mail or the password is wrong
        $error = 'Invalid e-mail or password.';
    }
}

render_header('Log in');
?>
<section class="panel narrow">
    <h1>Log in</h1>
    <?php if ($error): ?><div class="alert alert-error"><?= e($error) ?></div><?php endif; ?>
    <form method="post" action="login.php" class="form">
        <?= csrf_field() ?>
        <label for="email">E-mail</label>
        <input id="email" name="email" type="email" value="<?= e($email) ?>" autocomplete="username" required>

        <label for="password">Password</label>
        <input id="password" name="password" type="password" autocomplete="current-password" required>

        <button type="submit" class="btn">Log in</button>
    </form>
    <p class="muted">No account yet? <a href="register.php">Create one</a>.</p>
</section>
<?php render_footer(); ?>
