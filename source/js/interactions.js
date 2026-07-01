/* ============================================================
 * 归档/分类页交互增强 — 轻量、性能友好
 * 1) 滚动渐显(IntersectionObserver)
 * 2) 鼠标跟随光晕(rAF 节流,只动 transform)
 * 3) 卡片 3D 倾斜(pointermove,transform-only)
 * 4) 点击按压反馈(CSS :active 配合,JS 仅补强)
 * 全部在 prefers-reduced-motion 下降级为静态。
 * ============================================================ */
(function () {
  'use strict';
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  // 触摸设备不启用鼠标类交互(3D 倾斜 / 跟随光晕)
  var isTouch = window.matchMedia && window.matchMedia('(hover: none)').matches;

  function init() {
    var cards = [].slice.call(document.querySelectorAll(
      '.type-categories .category-list-item, #archive .article-sort-item:not(.year)'
    ));

    /* ---------- 1) 滚动渐显 ---------- */
    // 归档页文章多,进入动画用 IO 触发(替代纯 CSS 的固定延迟,更自然)
    if (!reduce && 'IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            e.target.classList.add('arc-in');
            io.unobserve(e.target);
          }
        });
      }, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });
      cards.forEach(function (c) { c.classList.add('arc-reveal'); io.observe(c); });
    }

    if (reduce || isTouch) return;

    /* ---------- 2) 鼠标墨水渲染(Canvas 墨迹拖尾) ---------- */
    // 鼠标移动时沿轨迹撒墨点,墨点扩散变大 + 淡出,像毛笔划过宣纸的青墨晕染
    var canvas = document.getElementById('ink-canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'ink-canvas';
      canvas.setAttribute('aria-hidden', 'true');
      document.body.appendChild(canvas);
    }
    var ctx = canvas.getContext('2d');
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    function resize() {
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;
      canvas.style.width = window.innerWidth + 'px';
      canvas.style.height = window.innerHeight + 'px';
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    resize();
    window.addEventListener('resize', resize, { passive: true });

    var drops = [];             // 墨点池
    var lastX = 0, lastY = 0, lastT = 0, rafInk = 0;
    // 深色模式偏亮青墨,浅色模式偏深青墨(整体加深)
    function inkColor(a) {
      var dark = document.documentElement.getAttribute('data-theme') === 'dark';
      return dark
        ? 'rgba(90, 190, 185,' + a + ')'
        : 'rgba(10, 80, 92,' + a + ')';      // 更深的青墨
    }
    function spawn(x, y, speed) {
      // 速度越快墨点越小越密,慢时墨点大(像停笔积墨)—— 整体放大晕染范围
      var base = Math.max(6, 30 - speed * 0.9);
      drops.push({
        x: x + (Math.random() - 0.5) * 8,
        y: y + (Math.random() - 0.5) * 8,
        r: base * (0.6 + Math.random() * 0.6),
        max: base * (2.4 + Math.random() * 1.6),   // 扩散终点更大
        a: 0.40 + Math.random() * 0.18,            // 墨色更浓
        life: 1
      });
      if (drops.length > 110) drops.splice(0, drops.length - 110);  // 上限,防堆积
    }
    function render() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      for (var i = drops.length - 1; i >= 0; i--) {
        var d = drops[i];
        d.life -= 0.007;                     // 淡出更慢(消失延迟更长)
        if (d.life <= 0) { drops.splice(i, 1); continue; }
        d.r += (d.max - d.r) * 0.045;        // 扩散变大(略慢,晕开更自然)
        var alpha = d.a * d.life;
        var g = ctx.createRadialGradient(d.x, d.y, 0, d.x, d.y, d.r);
        g.addColorStop(0, inkColor(alpha));
        g.addColorStop(0.6, inkColor(alpha * 0.5));
        g.addColorStop(1, inkColor(0));
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(d.x, d.y, d.r, 0, Math.PI * 2);
        ctx.fill();
      }
      if (drops.length) { rafInk = requestAnimationFrame(render); }
      else { rafInk = 0; ctx.clearRect(0, 0, canvas.width, canvas.height); }
    }
    window.addEventListener('pointermove', function (ev) {
      var now = ev.timeStamp || performance.now();
      var dx = ev.clientX - lastX, dy = ev.clientY - lastY, dt = now - lastT || 16;
      var speed = Math.sqrt(dx * dx + dy * dy) / dt * 16;   // 归一化速度
      // 在上一点到当前点之间插值撒墨,连成连续墨迹
      var dist = Math.sqrt(dx * dx + dy * dy);
      var steps = Math.min(6, Math.max(1, Math.floor(dist / 14)));
      for (var s = 1; s <= steps; s++) {
        spawn(lastX + dx * s / steps, lastY + dy * s / steps, speed);
      }
      lastX = ev.clientX; lastY = ev.clientY; lastT = now;
      if (!rafInk) rafInk = requestAnimationFrame(render);
    }, { passive: true });

    /* ---------- 3) 卡片 3D 倾斜 ---------- */
    cards.forEach(function (card) {
      var raf = 0, rx = 0, ry = 0;
      function apply() {
        card.style.transform =
          'perspective(700px) rotateX(' + rx + 'deg) rotateY(' + ry + 'deg) translateY(-4px)';
        raf = 0;
      }
      card.addEventListener('pointermove', function (ev) {
        var r = card.getBoundingClientRect();
        var px = (ev.clientX - r.left) / r.width;   // 0..1
        var py = (ev.clientY - r.top) / r.height;
        ry = (px - 0.5) * 8;      // 左右倾斜最大 ±4deg
        rx = (0.5 - py) * 8;      // 上下
        if (!raf) raf = requestAnimationFrame(apply);
      }, { passive: true });
      card.addEventListener('pointerleave', function () {
        if (raf) { cancelAnimationFrame(raf); raf = 0; }
        card.style.transform = '';   // 复位,交回 CSS
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else { init(); }

  // butterfly 用 pjax 切页时重新初始化
  document.addEventListener('pjax:complete', init);
})();
