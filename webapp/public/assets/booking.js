// Live total price on the booking form (display only - the server recomputes the real amount).
(function () {
    const form = document.getElementById('booking-form');
    if (!form) return;

    const eventSel = form.querySelector('#event_id');
    const seats = form.querySelector('#seats');
    const total = form.querySelector('#total');
    const fmt = new Intl.NumberFormat('fr-FR');
    const maxPerBooking = parseInt(seats.max, 10);

    function update() {
        const opt = eventSel.options[eventSel.selectedIndex];
        const price = parseFloat(opt && opt.dataset.price);
        const available = parseInt(opt && opt.dataset.available, 10);
        const n = parseInt(seats.value, 10);

        if (!isNaN(available)) {
            seats.max = Math.min(available, maxPerBooking);
        }
        total.textContent = (!isNaN(price) && n > 0) ? fmt.format(price * n) + ' FCFA' : '—';
    }

    eventSel.addEventListener('change', update);
    seats.addEventListener('input', update);
    update();
})();
