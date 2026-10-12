if (location.pathname === '/admin' || location.pathname.startsWith('/admin/')) {
  import('./admin/app.js').catch(() => {document.body.textContent='Newsroom could not load. Please refresh.';});
} else {
  import('./main.js').catch(() => {document.querySelector('#main').textContent='Unable to load the newsroom. Please refresh.';});
}
