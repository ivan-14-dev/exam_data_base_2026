import mysql, { type Pool } from "mysql2/promise";

declare global {
  // eslint-disable-next-line no-var
  var ictuDbPool: Pool | undefined;
}

export function getDb(): Pool {
  if (!globalThis.ictuDbPool) {
    globalThis.ictuDbPool = mysql.createPool({
      host: process.env.DB_HOST ?? "127.0.0.1",
      port: Number(process.env.DB_PORT ?? 3306),
      database: process.env.DB_NAME ?? "ictu_events",
      user: process.env.DB_USER ?? "ictu_app",
      password: process.env.DB_PASS,
      charset: "utf8mb4",
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      dateStrings: ["DATE"],
    });
  }

  return globalThis.ictuDbPool;
}