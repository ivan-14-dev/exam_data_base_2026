#!/usr/bin/env bash
# End-to-end smoke test of the web app (run against a test database only).
set -u
B=http://127.0.0.1:8080
J=$(mktemp)
tok() { grep -o 'name="csrf_token" value="[a-f0-9]*"' | head -1 | sed 's/.*value="//;s/"//'; }

echo "== 1. listing"
curl -s $B/index.php | grep -oE '<h2>[^<]+</h2>|[0-9]+ seats left|Sold out' | paste -sd' '
echo "== 2. search 'Cyber'"
curl -s "$B/index.php?q=Cyber" | grep -oE '<h2>[^<]+</h2>' | paste -sd' '
echo "== 3. SQL injection attempt in search"
curl -s "$B/index.php?q=%27%20OR%201%3D1%20--%20" | grep -oE '<h2>[^<]+</h2>|No event matches' | paste -sd' '
echo "== 4. book.php without login -> redirect"
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' $B/book.php
echo "== 5. login wrong password"
T=$(curl -s -c $J -b $J $B/login.php | tok)
curl -s -c $J -b $J -d "csrf_token=$T&email=nangu@ict.edu.cm&password=wrong" $B/login.php | grep -oE 'Invalid e-mail or password'
echo "== 6. login SQL injection in email"
T=$(curl -s -c $J -b $J $B/login.php | tok)
curl -s -c $J -b $J --data-urlencode "csrf_token=$T" --data-urlencode "email=' OR '1'='1' -- " --data-urlencode "password=x" $B/login.php | grep -oE 'Invalid e-mail or password'
echo "== 7. missing CSRF token"
curl -s -c $J -b $J -d "email=nangu@ict.edu.cm&password=Ictu@2026" $B/login.php
echo
echo "== 8. login OK"
T=$(curl -s -c $J -b $J $B/login.php | tok)
curl -s -c $J -b $J -o /dev/null -w '%{http_code} %{redirect_url}\n' -d "csrf_token=$T&email=nangu@ict.edu.cm&password=Ictu%402026" $B/login.php
echo "== 9. book 2 seats for event 1"
T=$(curl -s -c $J -b $J $B/book.php | tok)
curl -s -c $J -b $J -o /dev/null -w '%{http_code} %{redirect_url}\n' -d "csrf_token=$T&event_id=1&seats=2" $B/book.php
curl -s -c $J -b $J $B/book.php | grep -oE 'Booking #[0-9]+ confirmed'
echo "== 10. book too many seats (11) and invalid event"
T=$(curl -s -c $J -b $J $B/book.php | tok)
curl -s -c $J -b $J -d "csrf_token=$T&event_id=1&seats=11" $B/book.php | grep -oE 'Number of seats must be[^<]*'
curl -s -c $J -b $J -d "csrf_token=$T&event_id=99&seats=1" $B/book.php | grep -oE 'Event not found'
echo "== 11. register new user"
J2=$(mktemp)
T=$(curl -s -c $J2 -b $J2 $B/register.php | tok)
curl -s -c $J2 -b $J2 -o /dev/null -w '%{http_code} %{redirect_url}\n' --data-urlencode "csrf_token=$T" -d "first_name=Paul&last_name=Mbarga&email=mbarga@ict.edu.cm&phone=699000111&password=Secret123&password_confirm=Secret123" $B/register.php
T=$(curl -s -c $J2 -b $J2 $B/register.php | tok)
curl -s -c $J2 -b $J2 --data-urlencode "csrf_token=$T" -d "first_name=Paul&last_name=Mbarga&email=mbarga@ict.edu.cm&phone=&password=Secret123&password_confirm=Secret123" $B/register.php | grep -oE 'An account already exists[^<]*'
echo "== 12. lockout after 5 failures"
for i in 1 2 3 4 5 6; do T=$(curl -s -c $J2 -b $J2 $B/login.php | tok); curl -s -c $J2 -b $J2 -d "csrf_token=$T&email=mbarga@ict.edu.cm&password=bad$i" $B/login.php | grep -oE 'Invalid e-mail or password|account is locked' ; done
echo "== 13. XSS attempt in search is escaped"
curl -s "$B/index.php?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E" | grep -oE 'value="[^"]*script[^"]*"'
echo "== 14. security headers / cookie"
curl -s -D - -o /dev/null $B/login.php | grep -iE 'content-security|x-frame|x-content|set-cookie'
rm -f $J $J2
