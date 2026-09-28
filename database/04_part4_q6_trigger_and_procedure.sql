-- =====================================================================
-- File 04 : Part 4 Q6 - Automatic update of the available seats
--   * Trigger trg_bookings_after_insert : fires on EVERY insert into
--     bookings (web app, stored procedure, or a direct INSERT) and
--     decreases events.available_seats automatically.
--   * Stored procedure sp_make_booking : the booking entry point used by
--     the web application (validation, locking, price computed in SQL).
--   Created before the Part 4 queries (file 05) so Q1 is already covered.
-- =====================================================================
USE ictu_events;

DROP TRIGGER IF EXISTS trg_bookings_after_insert;
DROP PROCEDURE IF EXISTS sp_make_booking;

DELIMITER $$

-- ---------------------------------------------------------------------
-- Trigger: runs inside the same statement/transaction as the INSERT.
-- If the event does not have enough seats, SIGNAL cancels the INSERT.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_bookings_after_insert
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    -- Step 1: decrease the seats only if enough of them remain
    UPDATE events
    SET available_seats = available_seats - NEW.seats_booked
    WHERE event_id = NEW.event_id
      AND available_seats >= NEW.seats_booked;

    -- Step 2: no row updated = not enough seats -> the INSERT is rolled back
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available for this event';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- Stored procedure: book p_seats seats of p_event_id for p_attendee_id
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_make_booking(
    IN  p_attendee_id INT UNSIGNED,
    IN  p_event_id    INT UNSIGNED,
    IN  p_seats       INT,
    OUT p_booking_id  INT UNSIGNED
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_available INT UNSIGNED DEFAULT NULL;
    DECLARE v_price     DECIMAL(10,2);

    -- Step 1: on any error undo the whole transaction and re-raise it to the caller
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Step 2: validate the input
    IF p_seats IS NULL OR p_seats <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Number of seats must be greater than zero';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM attendees WHERE attendee_id = p_attendee_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Attendee not found';
    END IF;

    START TRANSACTION;

    -- Step 3: read and LOCK the event row (FOR UPDATE) so that two concurrent
    --         bookings cannot both take the last seats (no overselling)
    SELECT available_seats, ticket_price
      INTO v_available, v_price
    FROM events
    WHERE event_id = p_event_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Event not found';
    END IF;

    IF v_available < p_seats THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available for this event';
    END IF;

    -- Step 4: record the booking; the amount is computed server-side from the
    --         current ticket price (the client can never choose the price).
    --         The trigger trg_bookings_after_insert decreases the seats.
    INSERT INTO bookings (attendee_id, event_id, seats_booked, amount_paid, booking_date)
    VALUES (p_attendee_id, p_event_id, p_seats, v_price * p_seats, CURDATE());

    SET p_booking_id = LAST_INSERT_ID();

    COMMIT;
END$$

DELIMITER ;

SELECT TRIGGER_NAME, ACTION_TIMING, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'ictu_events';
