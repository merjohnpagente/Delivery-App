// Bings landing interactions. No dependencies.
(function () {
  // Reveal on scroll
  var els = document.querySelectorAll('.reveal');
  function show(el) { el.classList.add('visible'); }
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { show(e.target); io.unobserve(e.target); }
      });
    }, { threshold: 0.12 });
    els.forEach(function (el) { io.observe(el); });
  } else {
    els.forEach(show);
  }

  // Animated stat counters
  function countUp(el) {
    var target = parseFloat(el.getAttribute('data-count'));
    var decimals = parseInt(el.getAttribute('data-decimals') || '0', 10);
    var dur = 1200, start = null;
    function tick(now) {
      if (!start) start = now;
      var p = Math.min((now - start) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = (target * eased).toFixed(decimals);
      if (p < 1) requestAnimationFrame(tick);
      else el.textContent = target.toFixed(decimals);
    }
    requestAnimationFrame(tick);
  }
  var stats = document.querySelectorAll('[data-count]');
  if ('IntersectionObserver' in window) {
    var so = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { countUp(e.target); so.unobserve(e.target); }
      });
    }, { threshold: 0.4 });
    stats.forEach(function (el) { so.observe(el); });
  } else {
    stats.forEach(countUp);
  }

  // Active nav link
  var links = Array.prototype.slice.call(document.querySelectorAll('.nav-links a'));
  var ids = ['home', 'menu', 'about', 'contact'];
  function onScroll() {
    var cur = 'home';
    ids.forEach(function (id) {
      var s = document.getElementById(id);
      if (s && window.scrollY >= s.offsetTop - 140) cur = id;
    });
    links.forEach(function (a) {
      a.classList.toggle('active', a.getAttribute('href') === '#' + cur);
    });
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // Footer year
  var y = document.getElementById('year');
  if (y) y.textContent = new Date().getFullYear();
})();
