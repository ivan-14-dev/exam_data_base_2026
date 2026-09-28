<?php
// Part 5 Q3 - Secure registration: validated input, bcrypt password hash, transactional insert.
declare(strict_types=1);
require __DIR__ . '/../src/bootstrap.php';

if (current_user()) {
    redirect('index.php');
}

$errors = [];
$old = ['first_name' => '', 'last_name' => '', 'email' => '', 'phone' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_verify();

    // Step 1: normalise the input
    foreach ($old as $k => $_) {
        $old[$k] = trim((string) ($_POST[$k] ?? ''));
    }
    $old['email'] = mb_strtolower($old['email']);
    $password = (string) ($_POST['password'] ?? '');
    $confirm  = (string) ($_POST['password_confirm'] ?? '');

    // Step 2: server-side validation
    if (!preg_match('/^[\p{L}][\p{L}\' .-]{0,49}$/u', $old['first_name'])) {
        $errors[] = 'First name is required (letters only, max 50).';
    }
    if (!preg_match('/^[\p{L}][\p{L}\' .-]{0,49}$/u', $old['last_name'])) {
        $errors[] = 'Last name is required (letters only, max 50).';
    }
    if (!filter_var($old['email'], FILTER_VALIDATE_EMAIL) || mb_strlen($old['email']) > 120) {
        $errors[] = 'Please enter a valid e-mail address.';
    }
    if ($old['phone'] !== '' && !preg_match('/^\+?[0-9 ]{6,20}$/', $old['phone'])) {
        $errors[] = 'Phone number may contain digits, spaces and a leading + only.';
    }
    if (strlen($password) < 8 || !preg_match('/[A-Za-z]/', $password) || !preg_match('/\d/', $password)) {
        $errors[] = 'Password must be at least 8 characters and contain letters and digits.';
    }
    if (strlen($password) > 72) {
        $errors[] = 'Password must not exceed 72 characters.';
    }
    if ($password !== $confirm) {
        $errors[] = 'The two passwords do not match.';
    }

    // Step 3: create attendee + user in ONE transaction (all or nothing)
    if (!$errors) {
        $pdo = db();
        try {
            $pdo->beginTransaction();

            // Step 3a: reuse the attendee row if this e-mail already booked before (e.g. dataset attendees)
            $find = $pdo->prepare('SELECT attendee_id FROM attendees WHERE email = :email');
            $find->execute([':email' => $old['email']]);
            $attendeeId = $find->fetchColumn();

            if ($attendeeId === false) {
                $ins = $pdo->prepare(
                    'INSERT INTO attendees (first_name, last_name, email, phone)
                     VALUES (:fn, :ln, :email, :phone)'
                );
                $ins->execute([
                    ':fn'    => $old['first_name'],
                    ':ln'    => $old['last_name'],
                    ':email' => $old['email'],
                    ':phone' => $old['phone'] !== '' ? $old['phone'] : null,
                ]);
                $attendeeId = $pdo->lastInsertId();
            }

            // Step 3b: store only the bcrypt hash of the password
            $user = $pdo->prepare(
                'INSERT INTO users (attendee_id, email, password_hash, role)
                 VALUES (:aid, :email, :hash, \'ATTENDEE\')'
            );
            $user->execute([
                ':aid'   => (int) $attendeeId,
                ':email' => $old['email'],
                ':hash'  => password_hash($password, PASSWORD_DEFAULT),
            ]);

            $pdo->commit();
            flash('Account created. You can now log in.');
            redirect('login.php');
        } catch (PDOException $ex) {
            $pdo->rollBack();
            if ($ex->getCode() === '23000') {           // UNIQUE constraint on users.email / users.attendee_id
                $errors[] = 'An account already exists for this e-mail.';
            } else {
                error_log('Registration failed: ' . $ex->getMessage());
                $errors[] = 'Registration failed. Please try again later.';
            }
        }
    }
}

render_header('Register');
?>
<section class="panel narrow">
    <h1>Create an account</h1>
    <?php if ($errors): ?>
        <div class="alert alert-error"><ul><?php foreach ($errors as $err): ?><li><?= e($err) ?></li><?php endforeach; ?></ul></div>
    <?php endif; ?>
    <form method="post" action="register.php" class="form">
        <?= csrf_field() ?>
        <div class="row">
            <div>
                <label for="first_name">First name</label>
                <input id="first_name" name="first_name" value="<?= e($old['first_name']) ?>" maxlength="50" required>
            </div>
            <div>
                <label for="last_name">Last name</label>
                <input id="last_name" name="last_name" value="<?= e($old['last_name']) ?>" maxlength="50" required>
            </div>
        </div>
        <label for="email">E-mail</label>
        <input id="email" name="email" type="email" value="<?= e($old['email']) ?>" maxlength="120" autocomplete="username" required>

        <label for="phone">Phone (optional)</label>
        <input id="phone" name="phone" type="tel" value="<?= e($old['phone']) ?>" maxlength="20">

        <label for="password">Password</label>
        <input id="password" name="password" type="password" minlength="8" maxlength="72" autocomplete="new-password" required>

        <label for="password_confirm">Confirm password</label>
        <input id="password_confirm" name="password_confirm" type="password" minlength="8" maxlength="72" autocomplete="new-password" required>

        <button type="submit" class="btn">Register</button>
    </form>
    <p class="muted">Already registered? <a href="login.php">Log in</a>.</p>
</section>
<?php render_footer(); ?>
