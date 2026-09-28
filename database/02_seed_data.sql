-- =====================================================================
-- File 02 : Dataset (Part 2 - data exactly as given in the exam images)
-- =====================================================================
USE ictu_events;

-- Step 1: attendees
INSERT INTO attendees (attendee_id, first_name, last_name, email, phone) VALUES
    (1, 'John',   'Nangu', 'nangu@ict.edu.cm', '678475601'),
    (2, 'Pascal', 'Cho',   'cho@ict.edu.cm',   '677710578'),
    (3, 'Winnie', 'Onari', 'onari@ict.edu.cm', '690871033'),
    (4, 'Grace',  'Tima',  'tima@ict.edu.cm',  '655091237');

-- Step 2: speakers
INSERT INTO speakers (speaker_id, first_name, last_name, topic) VALUES
    (1, 'Prof', 'Ngwa',   'AI in Education'),
    (2, 'Dr',   'Cheikh', 'Cybersecurity Trends'),
    (3, 'Engr', 'Nanga',  'Web App Optimization');

-- Step 3: events (available_seats starts equal to total_seats, fixed in step 6)
INSERT INTO events (event_id, event_name, event_date, location, total_seats, available_seats, ticket_price) VALUES
    (1, 'Tech Conference 2025',     '2025-09-15', 'Main Hall',  100, 100, 15000.00),
    (2, 'Cybersecurity Workshop',   '2025-09-20', 'Lab A',       50,  50, 20000.00),
    (3, 'AI in Education Forum',    '2025-09-25', 'Auditorium', 150, 150, 10000.00);

-- Step 4: bookings (historical data, loaded as-is)
INSERT INTO bookings (booking_id, attendee_id, event_id, seats_booked, amount_paid, booking_date) VALUES
    (1, 1, 1, 2, 30000.00, '2025-08-01'),
    (2, 2, 1, 1, 15000.00, '2025-08-03'),
    (3, 3, 2, 1, 20000.00, '2025-08-05'),
    (4, 4, 3, 3, 30000.00, '2025-08-06');

-- Step 5: sessions
INSERT INTO sessions (session_id, event_id, speaker_id, session_title, start_time, end_time) VALUES
    (1, 1, 1, 'AI Overview',          '09:00', '10:30'),
    (2, 1, 3, 'Optimizing Web Apps',  '11:00', '12:30'),
    (3, 2, 2, 'Cyber Threats 2025',   '10:00', '12:00'),
    (4, 3, 1, 'AI in Classrooms',     '14:00', '15:30');

-- Step 6: synchronise available_seats with the historical bookings
--         (total_seats - SUM(seats_booked) for every event)
UPDATE events e
LEFT JOIN (SELECT event_id, SUM(seats_booked) AS booked
           FROM bookings GROUP BY event_id) b ON b.event_id = e.event_id
SET e.available_seats = e.total_seats - COALESCE(b.booked, 0);

-- Step 7: sample rows for the additional PAYMENTS table (one per booking)
INSERT INTO payments (booking_id, amount, payment_method, transaction_ref, status, paid_at) VALUES
    (1, 30000.00, 'MTN_MOMO',     'MOMO-20250801-0001', 'COMPLETED', '2025-08-01 10:15:00'),
    (2, 15000.00, 'ORANGE_MONEY', 'OM-20250803-0002',   'COMPLETED', '2025-08-03 14:02:00'),
    (3, 20000.00, 'CARD',         'CARD-20250805-0003', 'COMPLETED', '2025-08-05 09:40:00'),
    (4, 30000.00, 'CASH',         'CASH-20250806-0004', 'COMPLETED', '2025-08-06 16:25:00');

-- Step 8: demo login account for the web application (additional USERS table)
--   e-mail: nangu@ict.edu.cm   password: Ictu@2026   (bcrypt hash below)
INSERT INTO users (attendee_id, email, password_hash, role) VALUES
    (1, 'nangu@ict.edu.cm', '$2y$10$gkIWaEtvUTHoiDCLiNrimeQ2Ve1xFGWJqnMMDgxxh4KAV74ryPQMi', 'ATTENDEE');
