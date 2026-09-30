import type { Metadata } from "next";
import Link from "next/link";
import { registerAction } from "@/lib/actions";

export const metadata: Metadata = { title: "Create an account" };

const errors: Record<string, string> = {
  name: "Enter a valid first and last name.",
  email: "Please enter a valid e-mail address.",
  phone: "Phone numbers may contain digits, spaces and a leading + only.",
  password: "Use at least 8 characters, including letters and numbers.",
  confirmation: "The two passwords do not match.",
  exists: "An account already exists for this e-mail.",
};

export default async function RegisterPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const params = await searchParams;
  return (
    <section className="auth-layout register-layout">
      <div className="auth-aside">
        <p className="eyebrow">Be part of the conversation</p>
        <h1>Make room for what’s next.</h1>
        <p>Create your account to reserve a place at ICTU conferences and workshops.</p>
        <span className="aside-mark" aria-hidden="true">ICTU<span>.</span></span>
      </div>
      <div className="panel auth-panel">
        <p className="eyebrow">New member</p>
        <h2>Create an account</h2>
        {params.error && <div className="alert alert-error">{errors[params.error] ?? "Please check your details and try again."}</div>}
        <form action={registerAction} className="form">
          <div className="row">
            <div><label htmlFor="first_name">First name</label><input id="first_name" name="first_name" maxLength={50} autoComplete="given-name" required /></div>
            <div><label htmlFor="last_name">Last name</label><input id="last_name" name="last_name" maxLength={50} autoComplete="family-name" required /></div>
          </div>
          <label htmlFor="email">E-mail</label>
          <input id="email" name="email" type="email" maxLength={120} autoComplete="email" required />
          <label htmlFor="phone">Phone <span className="optional">Optional</span></label>
          <input id="phone" name="phone" type="tel" maxLength={20} autoComplete="tel" />
          <label htmlFor="password">Password</label>
          <input id="password" name="password" type="password" minLength={8} maxLength={72} autoComplete="new-password" required />
          <label htmlFor="password_confirm">Confirm password</label>
          <input id="password_confirm" name="password_confirm" type="password" minLength={8} maxLength={72} autoComplete="new-password" required />
          <button className="btn" type="submit">Create account <span aria-hidden="true">→</span></button>
        </form>
        <p className="muted auth-footnote">Already registered? <Link href="/login">Log in</Link>.</p>
      </div>
    </section>
  );
}