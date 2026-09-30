import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import "./globals.css";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: {
    default: "ICTU Events",
    template: "%s | ICTU Events",
  },
  description: "Browse ICTU conferences and workshops and reserve your seats.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <SiteHeader />
        <main className="container">{children}</main>
        <footer className="footer">ICTU Events Ltd · Conferences and workshops</footer>
      </body>
    </html>
  );
}