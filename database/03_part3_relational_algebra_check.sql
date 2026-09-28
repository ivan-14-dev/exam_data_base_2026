-- =====================================================================
-- File 03 : Part 3 - Relational Algebra queries translated to SQL
--           (used to verify the relational algebra answers of the report
--            against the ORIGINAL dataset - run right after file 02)
-- =====================================================================
USE ictu_events;

-- ---------------------------------------------------------------------
-- RA 1: attendees who booked more than 2 seats for any single event
--   T  <- attendee_id, event_id G SUM(seats_booked) -> seats (Bookings)
--   R1 <- PI attendee_id, first_name, last_name (SIGMA seats > 2 (T) |X| Attendees)
-- ---------------------------------------------------------------------
SELECT DISTINCT a.attendee_id, a.first_name, a.last_name
FROM attendees a
JOIN (SELECT attendee_id, event_id, SUM(seats_booked) AS seats   -- grouping G
      FROM bookings
      GROUP BY attendee_id, event_id) t ON t.attendee_id = a.attendee_id
WHERE t.seats > 2;                                                -- selection SIGMA

-- ---------------------------------------------------------------------
-- RA 2: events that are fully booked (no seats remaining)
--   B  <- event_id G SUM(seats_booked) -> booked (Bookings)
--   R2 <- PI event_id, event_name (SIGMA booked >= total_seats (Events |X| B))
-- ---------------------------------------------------------------------
SELECT e.event_id, e.event_name
FROM events e
JOIN (SELECT event_id, SUM(seats_booked) AS booked
      FROM bookings GROUP BY event_id) b ON b.event_id = e.event_id
WHERE b.booked >= e.total_seats;

-- ---------------------------------------------------------------------
-- RA 3: speakers presenting at more than one event (self-join form)
--   S1 <- RHO S1(Sessions), S2 <- RHO S2(Sessions)
--   R3 <- PI speaker_id, first_name, last_name, topic
--         (SIGMA S1.speaker_id = S2.speaker_id AND S1.event_id <> S2.event_id (S1 X S2) |X| Speakers)
-- ---------------------------------------------------------------------
SELECT DISTINCT sp.speaker_id, sp.first_name, sp.last_name, sp.topic
FROM sessions s1
JOIN sessions s2 ON s1.speaker_id = s2.speaker_id AND s1.event_id <> s2.event_id
JOIN speakers sp ON sp.speaker_id = s1.speaker_id;

-- ---------------------------------------------------------------------
-- RA 4: attendees who have not booked any event (set difference)
--   R4 <- (PI attendee_id (Attendees) - PI attendee_id (Bookings)) |X| Attendees
-- ---------------------------------------------------------------------
SELECT a.attendee_id, a.first_name, a.last_name
FROM attendees a
WHERE a.attendee_id NOT IN (SELECT b.attendee_id FROM bookings b);

-- ---------------------------------------------------------------------
-- RA 5: events whose total revenue is greater than 30 000
--   R  <- event_id G SUM(amount_paid) -> revenue (Bookings)
--   R5 <- PI event_id, event_name, revenue (SIGMA revenue > 30000 (R |X| Events))
-- ---------------------------------------------------------------------
SELECT e.event_id, e.event_name, r.revenue
FROM events e
JOIN (SELECT event_id, SUM(amount_paid) AS revenue
      FROM bookings GROUP BY event_id) r ON r.event_id = e.event_id
WHERE r.revenue > 30000;
