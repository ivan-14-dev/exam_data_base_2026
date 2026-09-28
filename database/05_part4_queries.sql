-- =====================================================================
-- File 05 : Part 4 - SQL Queries (Q1 to Q5) + demonstration of Q6
--   Requires file 04 (trigger + stored procedure) to be installed first.
-- =====================================================================
USE ictu_events;

-- ---------------------------------------------------------------------
-- Q1. Insert a new booking for attendee Alice Nzokou for the
--     Cybersecurity Workshop with 2 seats.
--   Alice is not in the dataset, so she is registered first. The seat
--   counter is decreased automatically by the trigger of Q6.
-- ---------------------------------------------------------------------
START TRANSACTION;

-- Step 1: register Alice only if her e-mail does not exist yet
INSERT INTO attendees (first_name, last_name, email, phone)
SELECT 'Alice', 'Nzokou', 'nzokou@ict.edu.cm', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM attendees WHERE email = 'nzokou@ict.edu.cm');

-- Step 2: look up Alice's id, the event id and its price (seats before booking)
SELECT attendee_id INTO @alice_id
FROM attendees
WHERE email = 'nzokou@ict.edu.cm';

SELECT event_id, ticket_price INTO @event_id, @price
FROM events
WHERE event_name = 'Cybersecurity Workshop';

SELECT event_id, event_name, available_seats AS seats_before
FROM events
WHERE event_id = @event_id;

-- Step 3: insert the booking (amount = 2 x ticket_price). VALUES is used instead of
--         INSERT ... SELECT FROM events because MySQL forbids a trigger from updating
--         a table read by the statement that fired it (error 1442).
--         The trigger refuses the booking if fewer than 2 seats remain.
INSERT INTO bookings (attendee_id, event_id, seats_booked, amount_paid, booking_date)
VALUES (@alice_id, @event_id, 2, @price * 2, CURDATE());

COMMIT;

-- Step 4: check the result (available_seats was decreased by the trigger)
SELECT b.booking_id, CONCAT(a.first_name, ' ', a.last_name) AS attendee,
       e.event_name, b.seats_booked, b.amount_paid, b.booking_date, e.available_seats
FROM bookings b
JOIN attendees a ON a.attendee_id = b.attendee_id
JOIN events e    ON e.event_id    = b.event_id
WHERE a.email = 'nzokou@ict.edu.cm';

-- ---------------------------------------------------------------------
-- Q2. Update the ticket price of "AI in Education Forum" to 12 000.
--   Only future bookings are affected; amount_paid of existing bookings
--   is historical and must not change.
-- ---------------------------------------------------------------------
UPDATE events
SET ticket_price = 12000.00
WHERE event_name = 'AI in Education Forum';

SELECT event_id, event_name, ticket_price
FROM events
WHERE event_name = 'AI in Education Forum';

-- ---------------------------------------------------------------------
-- Q3. Total revenue per event in descending order.
--   LEFT JOIN keeps events with no booking (revenue 0).
-- ---------------------------------------------------------------------
SELECT e.event_id,
       e.event_name,
       COALESCE(SUM(b.amount_paid), 0) AS total_revenue
FROM events e
LEFT JOIN bookings b ON b.event_id = e.event_id
GROUP BY e.event_id, e.event_name
ORDER BY total_revenue DESC;

-- ---------------------------------------------------------------------
-- Q4. All sessions with event name, speaker full name and session time.
-- ---------------------------------------------------------------------
SELECT s.session_id,
       e.event_name,
       CONCAT(sp.first_name, ' ', sp.last_name)       AS speaker_full_name,
       s.session_title,
       CONCAT(TIME_FORMAT(s.start_time, '%H:%i'), ' - ',
              TIME_FORMAT(s.end_time,   '%H:%i'))     AS session_time
FROM sessions s
JOIN events   e  ON e.event_id    = s.event_id
JOIN speakers sp ON sp.speaker_id = s.speaker_id
ORDER BY e.event_date, s.start_time;

-- ---------------------------------------------------------------------
-- Q5. Attendee who spent the most money on bookings.
--   Step 1 (CTE): total spent per attendee.
--   Step 2: keep the attendee(s) whose total equals the maximum, so a tie
--           returns every top spender instead of an arbitrary one (LIMIT 1).
-- ---------------------------------------------------------------------
WITH spending AS (
    SELECT a.attendee_id,
           CONCAT(a.first_name, ' ', a.last_name) AS attendee_name,
           SUM(b.amount_paid)                     AS total_spent
    FROM attendees a
    JOIN bookings b ON b.attendee_id = a.attendee_id
    GROUP BY a.attendee_id, a.first_name, a.last_name
)
SELECT attendee_id, attendee_name, total_spent
FROM spending
WHERE total_spent = (SELECT MAX(total_spent) FROM spending);

-- ---------------------------------------------------------------------
-- Q6. Demonstration: Winnie Onari (id 3) books 4 seats for
--     AI in Education Forum (id 3) through the stored procedure
-- ---------------------------------------------------------------------
SELECT event_id, event_name, available_seats AS seats_before FROM events WHERE event_id = 3;

CALL sp_make_booking(3, 3, 4, @new_booking_id);

SELECT @new_booking_id AS new_booking_id;
SELECT booking_id, attendee_id, event_id, seats_booked, amount_paid, booking_date
FROM bookings WHERE booking_id = @new_booking_id;
SELECT event_id, event_name, available_seats AS seats_after FROM events WHERE event_id = 3;

-- Error cases (run manually):
--   CALL sp_make_booking(2, 2, 500, @x);
--   -> ERROR 1644 (45000): Not enough seats available for this event
--   INSERT INTO bookings (attendee_id, event_id, seats_booked, amount_paid, booking_date)
--   VALUES (2, 2, 500, 0, CURDATE());
--   -> ERROR 1644 (45000): Not enough seats available for this event   (refused by the trigger)
