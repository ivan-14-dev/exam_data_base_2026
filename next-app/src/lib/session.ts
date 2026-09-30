import { getIronSession, type IronSession } from "iron-session";
import { cookies } from "next/headers";

export type SessionUser = {
  userId: number;
  attendeeId: number | null;
  email: string;
  firstName: string;
  lastName: string;
  role: "ATTENDEE" | "ADMIN";
};

const sessionOptions = {
  cookieName: "ictu_session",
  password: process.env.SESSION_SECRET ?? "",
  cookieOptions: {
    httpOnly: true,
    sameSite: "lax" as const,
    secure: process.env.NODE_ENV === "production",
    maxAge: 60 * 60 * 24 * 7,
    path: "/",
  },
};

export async function getSession(): Promise<IronSession<{ user?: SessionUser }>> {
  if (!sessionOptions.password || sessionOptions.password.length < 32) {
    throw new Error("Set SESSION_SECRET to a random value of at least 32 characters.");
  }

  return getIronSession<{ user?: SessionUser }>(await cookies(), sessionOptions);
}