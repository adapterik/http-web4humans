amd.define([], () => {
    return {
        log: (message) => {
            const timestamp = Intl.DateTimeFormat('en-US', {dateStyle: 'short', timeStyle: 'short'}).format(Date.now());
            console.log(`${timestamp}: ${message}`);
        },
        renderDates: () => {
            const toFormat = document.querySelectorAll('[data-renderer="format-date"]');
            toFormat.forEach((element) => {
              const time = parseInt(element.innerText, 10) * 1000;
              const formatted = new Intl.DateTimeFormat('en-US', {dateStyle: 'short', timeStyle: 'short'}).format(new Date(time));
              element.innerHTML = formatted;
            })
        }
    }
});

