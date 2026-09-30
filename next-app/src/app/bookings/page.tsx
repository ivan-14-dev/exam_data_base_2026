import type { Metadata } from "next";
import type { RowDataPacket } from "mysql2";
import { redirect } from "next/navigation";
import { BookingForm } from "@/components/booking-form";
import { getDb } from "@/lib/db";
import { formatDate, formatMoney } from "@/lib/format";
import { getSession } from "@/lib/session";

export const metadata: Metadata = { title: "Book a ticket" };

type EventRow = RowDataPacket & {
  event_id: number;
  event_name: string;
  event_date: string;
  ticket_price: string;
  available_seats: number;
};

type BookingRow = RowDataPacket & {
  booking_id: number;
  event_name: string;
  event_date: string;
  seats_booked: number;
  amount_paid: string;
  booking_date: string;
};

export default async function BookingsPage({
  searchParams,
}: {
  searchParams: Promise<{ event?: string; error?: string; confirmed?: string }>;
}) {
  const session = await getSession();
  if (!session.user?.attendeeId) redirect("/login?next=bookings");

  const params = await searchParams;
  const [events] = await getDb().execute<EventRow[]>(
    `SELECT event_id, event_name, event_date, ticket_price, available_seats
     FROM events WHERE available_seats > 0 ORDER BY event_date, event_name`,
  );
  const [bookings] = await getDb().execute<BookingRow[]>(
    `SELECT b.booking_id, e.event_name, e.event_date, b.seats_booked, b.amount_paid, b.booking_date
     FROM bookings b JOIN events e ON e.event_id = b.event_id
     WHERE b.attendee_id = ? ORDER BY b.booking_date DESC, b.booking_id DESC`,
    [session.user.attendeeId],
  );
  const selectedEventId = events.some((event) => String(event.event_id) === params.event)
    ? params.event!
    : String(events[0]?.event_id ?? "");

  return (
    <>
      <section className="page-heading">
        <p className="eyebrow">Your ICTU account</p>
        <h1>Bookings</h1>
        <p>Choose an event, reserve your seats, and keep your plans in one place.</p>
      </section>

      {params.confirmed && <div className="alert alert-success">Booking #{params.confirmed} confirmed. Thank you!</div>}
      {params.error && <div className="alert alert-error">{params.error === "seats" ? "Choose an event and select between 1 and 10 seats." : "Those seats are no longer available. Please choose again."}</div>}

      <section className="panel booking-panel">
        <div className="section-title"><div><p className="eyebrow">Make it official</p><h2>Book a ticket</h2></div><span className="section-number">01</span></div>
        {events.length === 0 ? (
          <p className="empty">All events are fully booked.</p>
        ) : (
          <BookingForm
            events={events}
            firstName={session.user.firstName}
            lastName={session.user.lastName}
            email={session.user.email}
            selectedEventId={selectedEventId}
          />
        )}
      </section>

      <section className="bookings-section">
        <div className="section-title"><div><p className="eyebrow">Your calendar</p><h2>My bookings</h2></div><span className="section-number">02</span></div>
        {bookings.length === 0 ? (
          <p className="empty">You have no bookings yet.</p>
        ) : (
          <div className="table-wrap">
            <table>
              <thead><tr><th>#</th><th>Event</th><th>Event date</th><th>Seats</th><th>Amount</th><th>Booked on</th></tr></thead>
              <tbody>{bookings.map((booking) => (
                <tr key={booking.booking_id}>
                  <td>{booking.booking_id}</td>
                  <td>{booking.event_name}</td>
                  <td>{formatDate(booking.event_date)}</td>
                  <td>{booking.seats_booked}</td>
                  <td>{formatMoney(booking.amount_paid)}</td>
                  <td>{formatDate(booking.booking_date)}</td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        )}
      </section>
    </>
  );
}