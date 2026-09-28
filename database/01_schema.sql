-- =====================================================================
-- SEN3102 - ICTU Events Ltd : Conference & Ticketing Management System
-- File 01 : Database schema (Part 1 - Database Design & Enhancement)
-- Target  : MySQL 8 / MariaDB 10.6+ (InnoDB, utf8mb4)
-- =====================================================================

-- Step 1: create a clean database using a full Unicode character set
DROP DATABASE IF EXISTS ictu_events;
CREATE DATABASE ictu_events CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ictu_events;

-- ---------------------------------------------------------------------
-- Step 2: ATTENDEES - people who buy tickets for events
-- ---------------------------------------------------------------------
CREATE TABLE attendees (
    attendee_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    phone        VARCHAR(20)  NULL,
    CONSTRAINT uq_attendees_email UNIQUE (email)       -- one attendee per e-mail
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Step 3: SPEAKERS - people who present sessions
-- ---------------------------------------------------------------------
CREATE TABLE speakers (
    speaker_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    topic        VARCHAR(150) NOT NULL
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Step 4: EVENTS - conferences / workshops that can be booked
--   available_seats is a derived column kept up to date automatically by the
--   trigger trg_bookings_after_insert (Part 4 Q6) so the listing page does not
--   have to aggregate the bookings table on every request.
-- ---------------------------------------------------------------------
CREATE TABLE events (
    event_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_name      VARCHAR(150)  NOT NULL,
    event_date      DATE          NOT NULL,
    location        VARCHAR(100)  NOT NULL,
    total_seats     INT UNSIGNED  NOT NULL,
    available_seats INT UNSIGNED  NOT NULL,
    ticket_price    DECIMAL(10,2) NOT NULL,
    CONSTRAINT uq_events_date_name   UNIQUE (event_date, event_name),
    CONSTRAINT ck_events_total_seats CHECK (total_seats > 0),
    CONSTRAINT ck_events_available   CHECK (available_seats <= total_seats),
    CONSTRAINT ck_events_price       CHECK (ticket_price >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Step 5: BOOKINGS - associative entity Attendee (M) <-> (N) Event
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
    booking_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attendee_id   INT UNSIGNED  NOT NULL,
    event_id      INT UNSIGNED  NOT NULL,
    seats_booked  INT UNSIGNED  NOT NULL,
    amount_paid   DECIMAL(10,2) NOT NULL,
    booking_date  DATE          NOT NULL,
    CONSTRAINT fk_bookings_attendee FOREIGN KEY (attendee_id)
        REFERENCES attendees (attendee_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_event    FOREIGN KEY (event_id)
        REFERENCES events (event_id)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_bookings_seats    CHECK (seats_booked > 0),
    CONSTRAINT ck_bookings_amount   CHECK (amount_paid >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Step 6: SESSIONS - associative entity Event (M) <-> (N) Speaker
-- ---------------------------------------------------------------------
CREATE TABLE sessions (
    session_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id      INT UNSIGNED NOT NULL,
    speaker_id    INT UNSIGNED NOT NULL,
    session_title VARCHAR(150) NOT NULL,
    start_time    TIME         NOT NULL,
    end_time      TIME         NOT NULL,
    CONSTRAINT fk_sessions_event   FOREIGN KEY (event_id)
        REFERENCES events (event_id)     ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_sessions_speaker FOREIGN KEY (speaker_id)
        REFERENCES speakers (speaker_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_sessions_time    CHECK (end_time > start_time)
) ENGINE = InnoDB;

-- =====================================================================
-- Part 1 Q2 - TWO ADDITIONAL TABLES
-- =====================================================================

-- ---------------------------------------------------------------------
-- Step 7 (additional table 1): PAYMENTS
--   Records every payment transaction for a booking (Mobile Money, card,
--   cash), its status and external reference. Allows partial payments,
--   refunds and financial auditing, which the single amount_paid column
--   of BOOKINGS cannot represent.
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT UNSIGNED  NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    payment_method  ENUM('MTN_MOMO','ORANGE_MONEY','CARD','CASH') NOT NULL,
    transaction_ref VARCHAR(64)   NOT NULL,
    status          ENUM('PENDING','COMPLETED','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    paid_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payments_ref     UNIQUE (transaction_ref),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_payments_amount  CHECK (amount > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Step 8 (additional table 2): USERS
--   Login accounts for the web application (Part 5 Q3). Stores only a
--   salted password hash, a role for authorisation, and counters used
--   to lock an account after repeated failed logins (brute-force defence).
--   Each attendee account is linked 1:1 to an ATTENDEES row.
-- ---------------------------------------------------------------------
CREATE TABLE users (
    user_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attendee_id     INT UNSIGNED NULL,
    email           VARCHAR(120) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    role            ENUM('ATTENDEE','ADMIN') NOT NULL DEFAULT 'ATTENDEE',
    failed_attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
    locked_until    DATETIME NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at   DATETIME NULL,
    CONSTRAINT uq_users_email    UNIQUE (email),
    CONSTRAINT uq_users_attendee UNIQUE (attendee_id),
    CONSTRAINT fk_users_attendee FOREIGN KEY (attendee_id)
        REFERENCES attendees (attendee_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;
