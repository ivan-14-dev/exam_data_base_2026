"use client";

import { useState } from "react";
import { bookingAction } from "@/lib/actions";
import { formatDate, formatMoney } from "@/lib/format";

type AvailableEvent = {
  event_id: number;
  event_name: string;
  event_date: string;
  ticket_price: string;
  available_seats: number;
};

export function BookingForm({
  events,
  firstName,
  lastName,
  email,
  selectedEventId,
}: {
  events: AvailableEvent[];
  firstName: string;
  lastName: string;
  email: string;
  selectedEventId: string;
}) {
  const [eventId, setEventId] = useState(selectedEventId);
  const [seats, setSeats] = useState(1);
  const selectedEvent = events.find((event) => String(event.event_id) === eventId);
  const total = selectedEvent ? Number(selectedEvent.ticket_price) * seats : 0;

  return (
    <form action={bookingAction} className="form booking-form">
      <label htmlFor="attendee">Attendee</label>
      <input id="attendee" value={`${firstName} ${lastName} (${email})`} disabled readOnly />

      <label htmlFor="event_id">Event</label>
      <select
        id="event_id"
        name="event_id"
        value={eventId}
        onChange={(event) => setEventId(event.target.value)}
        required
      >
        {events.map((event) => (
          <option key={event.event_id} value={event.event_id}>
            {event.event_name} | {formatDate(event.event_date)} | {formatMoney(event.ticket_price)} ({event.available_seats} left)
          </option>
        ))}
      </select>

      <label htmlFor="seats">Number of seats</label>
      <input
        id="seats"
        name="seats"
        type="number"
        min={1}
        max={Math.min(10, selectedEvent?.available_seats ?? 10)}
        value={seats}
        onChange={(event) => setSeats(Math.max(1, Number(event.target.value)))}
        required
      />

      <p className="total">Total to pay: <strong>{selectedEvent ? formatMoney(total) : "—"}</strong></p>
      <button className="btn" type="submit">Confirm booking</button>
    </form>
  );
}