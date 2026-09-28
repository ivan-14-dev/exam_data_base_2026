-- =====================================================================
-- File 07 : Least-privilege database account used by the web application
--   The PHP app never connects as root. It can only read/write the rows it
--   needs and execute the booking procedure (it cannot DROP/ALTER anything).
--   Replace the password before deployment and put it in DB_PASS (.env).
-- =====================================================================
USE ictu_events;

DROP USER IF EXISTS 'ictu_app'@'localhost';
DROP USER IF EXISTS 'ictu_app'@'127.0.0.1';
CREATE USER 'ictu_app'@'localhost' IDENTIFIED BY 'ChangeMe_Ictu#2026';
CREATE USER 'ictu_app'@'127.0.0.1' IDENTIFIED BY 'ChangeMe_Ictu#2026';

GRANT SELECT                 ON ictu_events.events    TO 'ictu_app'@'localhost', 'ictu_app'@'127.0.0.1';
GRANT SELECT                 ON ictu_events.bookings  TO 'ictu_app'@'localhost', 'ictu_app'@'127.0.0.1';
GRANT SELECT, INSERT         ON ictu_events.attendees TO 'ictu_app'@'localhost', 'ictu_app'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE ON ictu_events.users     TO 'ictu_app'@'localhost', 'ictu_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE ictu_events.sp_make_booking TO 'ictu_app'@'localhost', 'ictu_app'@'127.0.0.1';

FLUSH PRIVILEGES;
