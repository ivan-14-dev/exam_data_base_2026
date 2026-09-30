"use server";

import bcrypt from "bcryptjs";
import { redirect } from "next/navigation";
import type { ResultSetHeader, RowDataPacket } from "mysql2";
import { getDb } from "@/lib/db";
import { getSession } from "@/lib/session";

function value(formData: FormData, key: string): string {
  const item = formData.get(key);
  return typeof item === "string" ? item.trim() : "";
}

export async function loginAction(formData: FormData): Promise<void> {
  const email = value(formData, "email").toLowerCase();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) redirect("/login?error=invalid");

  const [rows] = await getDb().execute(
    `SELECT u.user_id, u.attendee_id, u.email, u.password_hash, u.role,
            (u.locked_until IS NOT NULL AND u.locked_until > NOW()) AS is_locked,
            a.first_name, a.last_name
     FROM users u
     LEFT JOIN attendees a ON a.attendee_id = u.attendee_id
     WHERE u.email = ? LIMIT 1`,
    [email],
  );
  const account = (rows as Array<{
    user_id: number;
    attendee_id: number | null;
    email: string;
    password_hash: string;
    role: "ATTENDEE" | "ADMIN";
    is_locked: number;
    first_name: string | null;
    last_name: string | null;
  }>)[0];

  if (account?.is_locked) redirect("/login?error=locked");

  const valid = await bcrypt.compare(
    password,
    account?.password_hash ?? "$2a$10$C6UzMDM.H6dfI/f/IKcEe.1wY4FQ6qVZsT7Y3WIz0pFjWnfF/hC4e",
  );

  if (!account || !valid) {
    if (account) {
      await getDb().execute(
        `UPDATE users
         SET locked_until = IF(failed_attempts + 1 >= ?, DATE_ADD(NOW(), INTERVAL ? MINUTE), locked_until),
             failed_attempts = IF(failed_attempts + 1 >= ?, 0, failed_attempts + 1)
         WHERE user_id = ?`,
        [5, 15, 5, account.user_id],
      );
    }
    redirect("/login?error=invalid");
  }

  await getDb().execute(
    "UPDATE users SET failed_attempts = 0, locked_until = NULL, last_login_at = NOW() WHERE user_id = ?",
    [account.user_id],
  );

  const session = await getSession();
  session.user = {
    userId: account.user_id,
    attendeeId: account.attendee_id,
    email: account.email,
    firstName: account.first_name ?? "",
    lastName: account.last_name ?? "",
    role: account.role,
  };
  await session.save();
  redirect("/bookings");
}

export async function registerAction(formData: FormData): Promise<void> {
  const firstName = value(formData, "first_name");
  const lastName = value(formData, "last_name");
  const email = value(formData, "email").toLowerCase();
  const phone = value(formData, "phone");
  const password = String(formData.get("password") ?? "");
  const confirmation = String(formData.get("password_confirm") ?? "");
  const namePattern = /^[\p{L}][\p{L}' .-]{0,49}$/u;

  if (!namePattern.test(firstName) || !namePattern.test(lastName)) {
    redirect("/register?error=name");
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 120) {
    redirect("/register?error=email");
  }
  if (phone && !/^\+?[0-9 ]{6,20}$/.test(phone)) redirect("/register?error=phone");
  if (password.length < 8 || password.length > 72 || !/[A-Za-z]/.test(password) || !/\d/.test(password)) {
    redirect("/register?error=password");
  }
  if (password !== confirmation) redirect("/register?error=confirmation");

  const connection = await getDb().getConnection();
  try {
    await connection.beginTransaction();
    const [attendees] = await connection.execute(
      "SELECT attendee_id FROM attendees WHERE email = ? LIMIT 1",
      [email],
    );
    let attendeeId = (attendees as Array<{ attendee_id: number }>)[0]?.attendee_id;

    if (!attendeeId) {
      const [insert] = await connection.execute<ResultSetHeader>(
        "INSERT INTO attendees (first_name, last_name, email, phone) VALUES (?, ?, ?, ?)",
        [firstName, lastName, email, phone || null],
      );
      attendeeId = insert.insertId;
    }

    await connection.execute(
      "INSERT INTO users (attendee_id, email, password_hash, role) VALUES (?, ?, ?, 'ATTENDEE')",
      [attendeeId, email, await bcrypt.hash(password, 10)],
    );
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    if ((error as { code?: string }).code === "ER_DUP_ENTRY") {
      redirect("/register?error=exists");
    }
    throw error;
  } finally {
    connection.release();
  }

  redirect("/login?created=1");
}

export async function bookingAction(formData: FormData): Promise<void> {
  const session = await getSession();
  if (!session.user?.attendeeId) redirect("/login?next=bookings");

  const eventId = Number(value(formData, "event_id"));
  const seats = Number(value(formData, "seats"));
  if (!Number.isInteger(eventId) || eventId < 1 || !Number.isInteger(seats) || seats < 1 || seats > 10) {
    redirect("/bookings?error=seats");
  }

  const connection = await getDb().getConnection();
  try {
    await connection.query("CALL sp_make_booking(?, ?, ?, @booking_id)", [
      session.user.attendeeId,
      eventId,
      seats,
    ]);
    const [result] = await connection.query<(RowDataPacket & { booking_id: number })[]>(
      "SELECT @booking_id AS booking_id",
    );
    redirect(`/bookings?confirmed=${Number(result[0]?.booking_id ?? 0)}`);
  } catch (error) {
    if ((error as { sqlState?: string }).sqlState === "45000") {
      redirect("/bookings?error=unavailable");
    }
    throw error;
  } finally {
    connection.release();
  }
}

export async function logoutAction(): Promise<void> {
  const session = await getSession();
  session.destroy();
  redirect("/");
}