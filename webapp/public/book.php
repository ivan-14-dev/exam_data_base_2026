<?php
// Part 5 Q2 - Ticket booking form linked to the database (through the stored procedure sp_make_booking).
declare(strict_types=1);
require __DIR__ . '/../src/bootstrap.php';

$user   = require_login();
$errors = [];
$maxSeats = $config['max_seats_per_booking'];

// Step 1: handle the submitted form
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_verify();

    // Step 1a: server-side validation (client-side checks can be bypassed)
    $eventId = filter_input(INPUT_POST, 'event_id', FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    $seats   = filter_input(INPUT_POST, 'seats', FILTER_VALIDATE_INT, ['options' => ['min_range' => 1, 'max_range' => $maxSeats]]);

    if (!$eventId) {
        $errors[] = 'Please choose an event.';
    }
    if (!$seats) {
        $errors[] = "Number of seats must be between 1 and $maxSeats.";
    }

    // Step 1b: call the stored procedure with a prepared statement; the attendee id comes
    //          from the authenticated session, never from the form, and the price is computed in SQL
    if (!$errors) {
        try {
            $pdo  = db();
            $call = $pdo->prepare('CALL sp_make_booking(:attendee_id, :event_id, :seats, @booking_id)');
            $call->bindValue(':attendee_id', (int) $user['attendee_id'], PDO::PARAM_INT);
            $call->bindValue(':event_id', $eventId, PDO::PARAM_INT);
            $call->bindValue(':seats', $seats, PDO::PARAM_INT);
            $call->execute();
            $call->closeCursor();

            $bookingId = (int) $pdo->query('SELECT @booking_id')->fetchColumn();

            // Step 1c: Post/Redirect/Get so refreshing the page cannot book twice
            flash("Booking #$bookingId confirmed. Thank you!");
            redirect('book.php');
        } catch (PDOException $ex) {
            if (($ex->errorInfo[0] ?? '') === '45000') {
                $errors[] = $ex->errorInfo[2];   // business-rule message raised by SIGNAL in the procedure
            } else {
                error_log('Booking failed: ' . $ex->getMessage());
                $errors[] = 'The booking could not be saved. Please try again later.';
            }
        }
    }
}

// Step 2: events that can still be booked, for the drop-down list
$events = db()->query(
    'SELECT event_id, event_name, event_date, ticket_price, available_seats
     FROM events
     WHERE available_seats > 0
     ORDER BY event_date, event_name'
)->fetchAll();

$selected = (int) ($_POST['event_id'] ?? $_GET['event_id'] ?? 0);
$seatsVal = (int) ($_POST['seats'] ?? 1);

// Step 3: bookings of the logged-in attendee
$mine = db()->prepare(
    'SELECT b.booking_id, e.event_name, e.event_date, b.seats_booked, b.amount_paid, b.booking_date
     FROM bookings b
     JOIN events e ON e.event_id = b.event_id
     WHERE b.attendee_id = :attendee_id
     ORDER BY b.booking_date DESC, b.booking_id DESC'
);
$mine->execute([':attendee_id' => (int) $user['attendee_id']]);
$myBookings = $mine->fetchAll();

render_header('Book a ticket');
?>
<section class="panel">
    <h1>Book a ticket</h1>

    <?php if ($errors): ?>
        <div class="alert alert-error"><ul><?php foreach ($errors as $err): ?><li><?= e($err) ?></li><?php endforeach; ?></ul></div>
    <?php endif; ?>

    <?php if (!$events): ?>
        <p class="empty">All events are fully booked.</p>
    <?php else: ?>
    <form method="post" action="book.php" class="form" id="booking-form" novalidate>
        <?= csrf_field() ?>

        <label for="attendee">Attendee</label>
        <input id="attendee" type="text" value="<?= e($user['first_name'] . ' ' . $user['last_name']) ?> (<?= e($user['email']) ?>)" disabled>

        <label for="event_id">Event</label>
        <select id="event_id" name="event_id" required>
            <option value="">-- Choose an event --</option>
            <?php foreach ($events as $ev): ?>
                <option value="<?= e($ev['event_id']) ?>"
                        data-price="<?= e($ev['ticket_price']) ?>"
                        data-available="<?= e($ev['available_seats']) ?>"
                        <?= $selected === (int) $ev['event_id'] ? 'selected' : '' ?>>
                    <?= e($ev['event_name']) ?> — <?= e($ev['event_date']) ?> — <?= e(money($ev['ticket_price'])) ?> (<?= e($ev['available_seats']) ?> left)
                </option>
            <?php endforeach; ?>
        </select>

        <label for="seats">Number of seats</label>
        <input id="seats" name="seats" type="number" min="1" max="<?= e($maxSeats) ?>" value="<?= e(max(1, $seatsVal)) ?>" required>

        <p class="total">Total to pay: <strong id="total">—</strong></p>

        <button type="submit" class="btn">Confirm booking</button>
    </form>
    <?php endif; ?>
</section>

<section class="panel">
    <h2>My bookings</h2>
    <?php if (!$myBookings): ?>
        <p class="empty">You have no booking yet.</p>
    <?php else: ?>
    <div class="table-wrap">
        <table>
            <thead><tr><th>#</th><th>Event</th><th>Event date</th><th>Seats</th><th>Amount</th><th>Booked on</th></tr></thead>
            <tbody>
            <?php foreach ($myBookings as $b): ?>
                <tr>
                    <td><?= e($b['booking_id']) ?></td>
                    <td><?= e($b['event_name']) ?></td>
                    <td><?= e($b['event_date']) ?></td>
                    <td><?= e($b['seats_booked']) ?></td>
                    <td><?= e(money($b['amount_paid'])) ?></td>
                    <td><?= e($b['booking_date']) ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php endif; ?>
</section>
<script src="assets/booking.js"></script>
<?php render_footer(); ?>
