import type { Metadata } from "next";
import Link from "next/link";
import { loginAction } from "@/lib/actions";

export const metadata: Metadata = { title: "Log in" };

const errors: Record<string, string> = {
  invalid: "Invalid e-mail or password.",
  locked: "Too many failed attempts. This account is temporarily locked.",
};

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; created?: string }>;
}) {
  const params = await searchParams;
  return (
    <section className="auth-layout">
      <div className="auth-aside">
        <p className="eyebrow">Your next idea starts here</p>
        <h1>Good to see you again.</h1>
        <p>Sign in to manage your bookings and get back to the events that move your work forward.</p>
        <span className="aside-mark" aria-hidden="true">ICTU<span>.</span></span>
      </div>
      <div className="panel auth-panel">
        <p className="eyebrow">Member access</p>
        <h2>Log in</h2>
        {params.created === "1" && <div className="alert alert-success">Account created. You can now log in.</div>}
        {params.error && <div className="alert alert-error">{errors[params.error] ?? "Please check your details and try again."}</div>}
        <form action={loginAction} className="form">
          <label htmlFor="email">E-mail</label>
          <input id="email" name="email" type="email" autoComplete="username" required />
          <label htmlFor="password">Password</label>
          <input id="password" name="password" type="password" autoComplete="current-password" required />
          <button className="btn" type="submit">Log in <span aria-hidden="true">→</span></button>
        </form>
        <p className="muted auth-footnote">No account yet? <Link href="/register">Create one</Link>.</p>
      </div>
    </section>
  );
}