export function formatMoney(amount: number | string): string {
  return `${new Intl.NumberFormat("fr-FR").format(Number(amount))} FCFA`;
}

export function formatDate(date: string | Date): string {
  const parsed = date instanceof Date ? date : new Date(`${date}T12:00:00`);
  return new Intl.DateTimeFormat("en-GB", {
    weekday: "short",
    day: "2-digit",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  }).format(parsed);
}