import Link from "next/link";
import { logoutAction } from "@/lib/actions";
import { getSession } from "@/lib/session";

export async function SiteHeader() {
  const session = await getSession();
  const user = session.user;

  return (
    <header className="topbar">
      <Link className="brand" href="/" aria-label="ICTU Events home">
        ICTU <span>Events</span>
      </Link>
      <nav aria-label="Main navigation">
        <Link href="/">Events</Link>
        <Link href="/bookings">Book a ticket</Link>
        {user ? (
          <>
            <span className="who">Hi, {user.firstName}</span>
            <form action={logoutAction}>
              <button className="nav-link" type="submit">Log out</button>
            </form>
          </>
        ) : (
          <>
            <Link href="/login">Log in</Link>
            <Link className="nav-register" href="/register">Register</Link>
          </>
        )}
      </nav>
    </header>
  );
}