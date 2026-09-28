<?php
// Part 5 Q1 - Responsive event listing page showing every event with its available seats.
declare(strict_types=1);
require __DIR__ . '/../src/bootstrap.php';

// Step 1: read and validate the optional filters from the query string
$search    = trim((string) ($_GET['q'] ?? ''));
$search    = mb_substr($search, 0, 100);
$onlyAvail = isset($_GET['available']);

// Step 2: build the query with placeholders only (user input never enters the SQL text)
$sql = 'SELECT event_id, event_name, event_date, location, total_seats, available_seats, ticket_price
        FROM events
        WHERE 1 = 1';
$params = [];

if ($search !== '') {
    // Prefix search so the B-tree index idx_events_event_name can be used; % and _ are escaped
    $sql .= ' AND event_name LIKE :search';
    $params[':search'] = addcslashes($search, '\\%_') . '%';
}
if ($onlyAvail) {
    $sql .= ' AND available_seats > 0';
}
$sql .= ' ORDER BY event_date, event_name';

// Step 3: execute the prepared statement
$stmt = db()->prepare($sql);
$stmt->execute($params);
$events = $stmt->fetchAll();

render_header('Events');
?>
<section class="hero">
    <h1>Upcoming conferences &amp; workshops</h1>
    <p>Browse the events organised by ICTU Events Ltd and reserve your seats online.</p>
    <form class="search" method="get" action="index.php" role="search">
        <input type="search" name="q" value="<?= e($search) ?>" placeholder="Search an event name…" maxlength="100" aria-label="Search events">
        <label class="check"><input type="checkbox" name="available" <?= $onlyAvail ? 'checked' : '' ?>> Only events with seats left</label>
        <button type="submit" class="btn">Search</button>
    </form>
</section>

<?php if (!$events): ?>
    <p class="empty">No event matches your search.</p>
<?php else: ?>
<section class="grid">
    <?php foreach ($events as $ev):
        $available = (int) $ev['available_seats'];
        $total     = (int) $ev['total_seats'];
        $percent   = $total > 0 ? (int) round(100 * ($total - $available) / $total) : 100;
        $soldOut   = $available === 0;
    ?>
    <article class="card">
        <header>
            <h2><?= e($ev['event_name']) ?></h2>
            <span class="badge <?= $soldOut ? 'badge-red' : 'badge-green' ?>">
                <?= $soldOut ? 'Sold out' : e($available) . ' seats left' ?>
            </span>
        </header>
        <ul class="meta">
            <li><strong>Date:</strong> <?= e(date('D, d M Y', strtotime($ev['event_date']))) ?></li>
            <li><strong>Location:</strong> <?= e($ev['location']) ?></li>
            <li><strong>Price:</strong> <?= e(money($ev['ticket_price'])) ?> / seat</li>
            <li><strong>Seats:</strong> <?= e($available) ?> available of <?= e($total) ?></li>
        </ul>
        <progress class="bar" max="100" value="<?= e($percent) ?>" title="<?= e($percent) ?>% booked"></progress>
        <?php if ($soldOut): ?>
            <span class="btn btn-disabled" aria-disabled="true">Fully booked</span>
        <?php else: ?>
            <a class="btn" href="book.php?event_id=<?= e($ev['event_id']) ?>">Book now</a>
        <?php endif; ?>
    </article>
    <?php endforeach; ?>
</section>
<?php endif; ?>
<?php render_footer(); ?>
