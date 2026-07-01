/* ============================================================
 * 喵喵鱼塘 · 水塘生命体背景
 * 常驻 Canvas:青墨底上有水墨鱼影缓慢游动 + 零星雨落涟漪。
 * 全站背景层(z-index 在烟雾之上、内容之下)。
 * 性能:rAF 驱动,页面隐藏时暂停;reduced-motion 静止;
 *       触摸/小屏减少鱼数;devicePixelRatio 上限 2。
 * ============================================================ */
(function () {
  'use strict';
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function init() {
    if (document.getElementById('pond-canvas')) return;   // 防重复(pjax)
    var canvas = document.createElement('canvas');
    canvas.id = 'pond-canvas';
    canvas.setAttribute('aria-hidden', 'true');
    document.body.appendChild(canvas);
    var ctx = canvas.getContext('2d');
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var W = 0, H = 0;

    function resize() {
      W = window.innerWidth; H = window.innerHeight;
      canvas.width = W * dpr; canvas.height = H * dpr;
      canvas.style.width = W + 'px'; canvas.style.height = H + 'px';
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    resize();
    window.addEventListener('resize', resize, { passive: true });

    function isDark() { return document.documentElement.getAttribute('data-theme') === 'dark'; }
    function ink(a) {
      return isDark() ? 'rgba(120,205,198,' + a + ')' : 'rgba(12,95,108,' + a + ')';
    }

    /* ---------- 鱼 ---------- */
    var small = W < 720;
    var FISH_N = reduce ? 0 : (small ? 2 : 4);
    var fish = [];
    // 伪随机(不用 Math.random 也行,但这里用于视觉抖动可接受)
    function rand(a, b) { return a + Math.random() * (b - a); }
    for (var i = 0; i < FISH_N; i++) {
      fish.push({
        x: rand(0.1, 0.9) * W,
        y: rand(0.15, 0.85) * H,
        a: rand(0, Math.PI * 2),        // 朝向角
        speed: rand(0.25, 0.55),        // 慢速游动
        size: rand(16, 30),
        wob: rand(0, Math.PI * 2),      // 摆尾相位
        turn: rand(-0.004, 0.004)       // 转向倾向
      });
    }
    function drawFish(f, t) {
      f.wob += 0.12;
      // 偶尔改变转向,自然游动
      if (Math.random() < 0.01) f.turn = rand(-0.006, 0.006);
      f.a += f.turn + Math.sin(f.wob) * 0.006;   // 摆尾带来的微摆
      f.x += Math.cos(f.a) * f.speed;
      f.y += Math.sin(f.a) * f.speed;
      // 边界回游(软转向)
      var m = 60;
      if (f.x < m) f.a += 0.03; if (f.x > W - m) f.a += 0.03;
      if (f.y < m) f.a += 0.03; if (f.y > H - m) f.a += 0.03;
      // 环绕兜底
      if (f.x < -50) f.x = W + 50; if (f.x > W + 50) f.x = -50;
      if (f.y < -50) f.y = H + 50; if (f.y > H + 50) f.y = -50;

      ctx.save();
      ctx.translate(f.x, f.y);
      ctx.rotate(f.a);
      var s = f.size;
      var tail = Math.sin(f.wob) * s * 0.28;   // 尾摆幅度
      // 身体(水墨椭圆,头朝 +x)
      ctx.beginPath();
      ctx.moveTo(s * 0.55, 0);
      ctx.quadraticCurveTo(0, -s * 0.32, -s * 0.5, tail * 0.4);
      ctx.quadraticCurveTo(-s * 0.2, 0, -s * 0.5, tail * 0.4);
      ctx.quadraticCurveTo(0, s * 0.32, s * 0.55, 0);
      ctx.closePath();
      ctx.fillStyle = ink(0.28);
      ctx.fill();
      // 尾鳍(三角,随摆动)
      ctx.beginPath();
      ctx.moveTo(-s * 0.42, tail * 0.3);
      ctx.lineTo(-s * 0.9, tail - s * 0.28);
      ctx.lineTo(-s * 0.9, tail + s * 0.28);
      ctx.closePath();
      ctx.fillStyle = ink(0.20);
      ctx.fill();
      ctx.restore();
    }

    /* ---------- 雨涟漪 ---------- */
    var ripples = [];
    var rainTimer = 0;
    function spawnRipple() {
      ripples.push({
        x: rand(0.05, 0.95) * W,
        y: rand(0.05, 0.95) * H,
        r: 1,
        max: rand(28, 60),
        life: 1
      });
      if (ripples.length > 24) ripples.shift();
    }
    function drawRipples() {
      for (var i = ripples.length - 1; i >= 0; i--) {
        var p = ripples[i];
        p.life -= 0.012;
        if (p.life <= 0) { ripples.splice(i, 1); continue; }
        p.r += (p.max - p.r) * 0.05;
        // 外圈
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
        ctx.strokeStyle = ink(0.22 * p.life);
        ctx.lineWidth = 1.2;
        ctx.stroke();
        // 内圈(细,滞后)
        if (p.r > 10) {
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.r * 0.6, 0, Math.PI * 2);
          ctx.strokeStyle = ink(0.14 * p.life);
          ctx.lineWidth = 0.8;
          ctx.stroke();
        }
      }
    }

    /* ---------- 主循环 ---------- */
    var raf = 0, running = true;
    var t = 0;
    function loop() {
      if (!running) { raf = 0; return; }
      t++;
      ctx.clearRect(0, 0, W, H);
      // 零星小雨:平均每 ~90 帧落一滴
      rainTimer++;
      if (rainTimer > rand(70, 130)) { spawnRipple(); rainTimer = 0; }
      drawRipples();
      for (var i = 0; i < fish.length; i++) drawFish(fish[i], t);
      raf = requestAnimationFrame(loop);
    }

    if (!reduce) { running = true; loop(); }
    else {
      // 静止:画一帧鱼,不动
      for (var i = 0; i < fish.length; i++) drawFish(fish[i], 0);
    }

    // 页面隐藏时暂停,省电省性能
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) { running = false; if (raf) cancelAnimationFrame(raf); raf = 0; }
      else if (!reduce && !raf) { running = true; loop(); }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else { init(); }
  document.addEventListener('pjax:complete', init);
})();
