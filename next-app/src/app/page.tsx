import Link from "next/link";
import type { RowDataPacket } from "mysql2";
import { getDb } from "@/lib/db";
import { formatDate, formatMoney } from "@/lib/format";

type EventRow = RowDataPacket & {
  event_id: number;
  event_name: string;
  event_date: string;
  location: string;
  total_seats: number;
  available_seats: number;
  ticket_price: string;
};

export default async function Home({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; available?: string }>;
}) {
  const params = await searchParams;
  const search = (params.q ?? "").trim().slice(0, 100);
  const onlyAvailable = params.available === "1";
  const conditions: string[] = [];
  const values: (string | number)[] = [];

  if (search) {
    conditions.push("event_name LIKE ?");
    values.push(`${search.replace(/[\\%_]/g, "\\$&")}%`);
  }
  if (onlyAvailable) conditions.push("available_seats > 0");

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
  const [events] = await getDb().execute<EventRow[]>(
    `SELECT event_id, event_name, event_date, location, total_seats, available_seats, ticket_price
     FROM events ${where} ORDER BY event_date, event_name`,
    values,
  );

  return (
    <>
      <section className="hero">
        <p className="eyebrow">ICTU Events Ltd · Live listings</p>
        <h1>Upcoming conferences &amp; workshops</h1>
        <p className="hero-copy">Find your next idea, meet the people shaping it, and save your seat.</p>
        <form className="search" method="get" action="/" role="search">
          <input
            type="search"
            name="q"
            defaultValue={search}
            placeholder="Search an event name…"
            maxLength={100}
            aria-label="Search events"
          />
          <label className="check">
            <input type="checkbox" name="available" value="1" defaultChecked={onlyAvailable} />
            Only events with seats left
          </label>
          <button className="btn" type="submit">Search events</button>
        </form>
      </section>

      <section className="results-heading" aria-live="polite">
        <h2>On the calendar</h2>
        <span>{events.length} {events.length === 1 ? "event" : "events"}</span>
      </section>

      {events.length === 0 ? (
        <p className="empty">No event matches your search.</p>
      ) : (
        <section className="grid" aria-label="Upcoming events">
          {events.map((event, index) => {
            const percent = event.total_seats
              ? Math.round(100 * (event.total_seats - event.available_seats) / event.total_seats)
              : 100;
            const soldOut = event.available_seats === 0;
            return (
              <article className={`event-card event-card-${index % 3}`} key={event.event_id}>
                <div className="event-card-topline">
                  <span className="event-date">{formatDate(event.event_date)}</span>
                  <span className={`badge ${soldOut ? "badge-red" : "badge-green"}`}>
                    {soldOut ? "Sold out" : `${event.available_seats} seats left`}
                  </span>
                </div>
                <h3>{event.event_name}</h3>
                <p className="event-location">{event.location}</p>
                <div className="event-price">{formatMoney(event.ticket_price)} <span>/ seat</span></div>
                <div className="seat-meter">
                  <div className="seat-meter-label"><span>Seats booked</span><span>{percent}%</span></div>
                  <progress max={100} value={percent} aria-label={`${percent}% booked`} />
                </div>
                <p className="seat-count">{event.available_seats} available of {event.total_seats}</p>
                {soldOut ? (
                  <span className="btn btn-disabled" aria-disabled="true">Fully booked</span>
                ) : (
                  <Link className="btn" href={`/bookings?event=${event.event_id}`}>Book a seat <span aria-hidden="true">↗</span></Link>
                )}
              </article>
            );
          })}
        </section>
      )}
    </>
  );
}