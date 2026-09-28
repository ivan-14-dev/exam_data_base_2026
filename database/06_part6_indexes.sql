-- =====================================================================
-- File 06 : Part 6 Q1 - Indexes for searches on event names and
--           booking dates
-- =====================================================================
USE ictu_events;

-- Step 1: plan BEFORE the indexes (full table scan expected: type = ALL)
EXPLAIN SELECT event_id, event_name FROM events WHERE event_name LIKE 'Cyber%';
EXPLAIN SELECT booking_id, booking_date FROM bookings
        WHERE booking_date BETWEEN '2025-08-01' AND '2025-08-05';

-- Step 2: B-tree index on event_name - used by equality searches
--         (WHERE event_name = ?) and prefix searches (LIKE 'abc%')
CREATE INDEX idx_events_event_name ON events (event_name);

-- Step 3: B-tree index on booking_date - used by date equality, ranges
--         (BETWEEN, >=, <) and ORDER BY booking_date
CREATE INDEX idx_bookings_booking_date ON bookings (booking_date);

-- Step 4: composite index for "bookings of an event within a period"
--         (event_id first = equality column, booking_date second = range)
CREATE INDEX idx_bookings_event_date ON bookings (event_id, booking_date);

-- Step 5: plan AFTER the indexes (type = range, key = the new index)
--         FORCE INDEX is only needed here because the demo tables are tiny and
--         the optimiser would otherwise prefer a scan; on real volumes it picks
--         the index by itself.
EXPLAIN SELECT event_id, event_name FROM events FORCE INDEX (idx_events_event_name)
        WHERE event_name LIKE 'Cyber%';
EXPLAIN SELECT booking_id, booking_date FROM bookings FORCE INDEX (idx_bookings_booking_date)
        WHERE booking_date BETWEEN '2025-08-01' AND '2025-08-05';

SHOW INDEX FROM events;
SHOW INDEX FROM bookings;
