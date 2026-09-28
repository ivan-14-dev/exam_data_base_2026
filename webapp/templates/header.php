<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($title) ?> | ICTU Events</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header class="topbar">
    <a class="brand" href="index.php">ICTU <span>Events</span></a>
    <nav>
        <a href="index.php">Events</a>
        <a href="book.php">Book a ticket</a>
        <?php if ($user): ?>
            <span class="who">Hi, <?= e($user['first_name']) ?></span>
            <form method="post" action="logout.php" class="inline">
                <?= csrf_field() ?>
                <button type="submit" class="link">Log out</button>
            </form>
        <?php else: ?>
            <a href="login.php">Log in</a>
            <a href="register.php" class="btn btn-small">Register</a>
        <?php endif; ?>
    </nav>
</header>
<main class="container">
<?php if ($f = flash()): ?>
    <div class="alert alert-<?= e($f['type']) ?>"><?= e($f['message']) ?></div>
<?php endif; ?>
