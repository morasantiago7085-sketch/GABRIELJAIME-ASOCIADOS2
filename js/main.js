document.addEventListener('DOMContentLoaded', function(){
  var reveals = document.querySelectorAll('.reveal');
  var obs = new IntersectionObserver(function(entries){
    entries.forEach(function(entry){
      if(entry.isIntersecting){ entry.target.classList.add('visible'); }
    });
  }, {threshold: 0.15});
  reveals.forEach(function(r){ obs.observe(r); });
  function countUp(el, end, duration){
    var start = 0; var current = start; var increment = end > start ? 1 : -1;
    var stepTime = Math.abs(Math.floor(duration / end)) || 20;
    var timer = setInterval(function(){
      current += increment;
      el.textContent = current;
      if(current == end){ clearInterval(timer); }
    }, stepTime);
  }
  var items = document.querySelectorAll('[data-count]');
  items.forEach(function(it){
    var end = parseInt(it.getAttribute('data-count'),10) || 0;
    countUp(it, end, 1000);
  });

  /* NAVIGATION TOGGLE (hamburger) */
  var navToggle = document.querySelector('.nav-toggle');
  var nav = document.querySelector('.nav');
  if(navToggle && nav){
    navToggle.addEventListener('click', function(e){
      e.stopPropagation();
      var isOpen = nav.classList.toggle('open');
      // animate bars
      navToggle.classList.toggle('open');
      // update accessible state
      navToggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    });
    // Close nav when clicking a link
    nav.querySelectorAll('a').forEach(function(a){ a.addEventListener('click', function(){ nav.classList.remove('open'); navToggle.classList.remove('open'); }); });
    // Close when clicking outside
    document.addEventListener('click', function(e){ if(!nav.contains(e.target) && !navToggle.contains(e.target)){ nav.classList.remove('open'); navToggle.classList.remove('open'); } });
  }
});