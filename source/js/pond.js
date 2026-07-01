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

    /* 写实贝塞尔鱼(数量少,更精致) */
    var REAL_N = reduce ? 0 : (small ? 1 : 2);
    var realFish = [];
    for (var j = 0; j < REAL_N; j++) {
      realFish.push({
        x: rand(0.15, 0.85) * W,
        y: rand(0.2, 0.8) * H,
        a: rand(0, Math.PI * 2),
        speed: rand(0.35, 0.7),         // 略快,显得更灵动
        size: rand(26, 42),             // 略大,细节看得清
        wob: rand(0, Math.PI * 2),
        turn: rand(-0.004, 0.004)
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

    /* 复用的游动更新(边界回游 + 环绕) */
    function swim(f, wobStep, jitter) {
      f.wob += wobStep;
      if (Math.random() < 0.01) f.turn = rand(-0.006, 0.006);
      f.a += f.turn + Math.sin(f.wob) * jitter;
      f.x += Math.cos(f.a) * f.speed;
      f.y += Math.sin(f.a) * f.speed;
      var m = 70;
      if (f.x < m) f.a += 0.03; if (f.x > W - m) f.a += 0.03;
      if (f.y < m) f.a += 0.03; if (f.y > H - m) f.a += 0.03;
      if (f.x < -60) f.x = W + 60; if (f.x > W + 60) f.x = -60;
      if (f.y < -60) f.y = H + 60; if (f.y > H + 60) f.y = -60;
    }

    /* ---------- 写实贝塞尔鱼 ---------- */
    function drawRealisticFish(f) {
      swim(f, 0.14, 0.008);
      var s = f.size;
      var w = Math.sin(f.wob);
      var tail = w * s * 0.5;            // 尾摆
      var body = w * s * 0.05;           // 身体随摆动的轻微 S 形

      ctx.save();
      ctx.translate(f.x, f.y);
      ctx.rotate(f.a);

      // 身体:贝塞尔流线型(头在 +x,尾在 -x),上下对称的两段三次曲线
      ctx.beginPath();
      ctx.moveTo(s * 0.72, 0);                                   // 吻部
      ctx.bezierCurveTo(s * 0.5, -s * 0.30, -s * 0.1, -s * 0.34, -s * 0.55, -body - s * 0.10); // 上缘 -> 尾柄
      ctx.bezierCurveTo(-s * 0.62, -body, -s * 0.62, body, -s * 0.55, body + s * 0.10);        // 尾柄圆转
      ctx.bezierCurveTo(-s * 0.1, s * 0.34, s * 0.5, s * 0.30, s * 0.72, 0);                     // 下缘 -> 吻部
      ctx.closePath();
      ctx.fillStyle = ink(0.34);
      ctx.fill();

      // 尾鳍:两片飘动的贝塞尔叶片
      ctx.beginPath();
      ctx.moveTo(-s * 0.5, body * 0.4);
      ctx.quadraticCurveTo(-s * 0.85, tail - s * 0.02, -s * 1.05, tail - s * 0.34);
      ctx.quadraticCurveTo(-s * 0.78, tail * 0.5, -s * 0.5, body * 0.4);
      ctx.moveTo(-s * 0.5, body * 0.4);
      ctx.quadraticCurveTo(-s * 0.85, tail + s * 0.02, -s * 1.05, tail + s * 0.34);
      ctx.quadraticCurveTo(-s * 0.78, tail * 0.5, -s * 0.5, body * 0.4);
      ctx.fillStyle = ink(0.22);
      ctx.fill();

      // 背鳍(上)
      ctx.beginPath();
      ctx.moveTo(s * 0.15, -s * 0.30);
      ctx.quadraticCurveTo(-s * 0.05, -s * 0.55, -s * 0.28, -s * 0.28);
      ctx.closePath();
      ctx.fillStyle = ink(0.18);
      ctx.fill();

      // 胸鳍(下,随摆动)
      ctx.beginPath();
      ctx.moveTo(s * 0.18, s * 0.22);
      ctx.quadraticCurveTo(s * 0.0, s * 0.42 + w * s * 0.06, -s * 0.12, s * 0.22);
      ctx.closePath();
      ctx.fillStyle = ink(0.16);
      ctx.fill();

      // 眼睛(小点,点睛)
      ctx.beginPath();
      ctx.arc(s * 0.46, -s * 0.06, s * 0.045, 0, Math.PI * 2);
      ctx.fillStyle = ink(0.5);
      ctx.fill();

      ctx.restore();
    }

    /* ---------- 水流波动 + 细密水波纹 ---------- */
    // 多层正弦水纹横贯:每条水纹配一条错位高光线(波峰亮/波谷暗),
    // 再叠一层更细密的次级波纹,让水面更有波光粼粼的质感。
    function waveY(x, baseY, phase, amp) {
      return baseY
        + Math.sin(x * 0.006 + phase) * amp
        + Math.sin(x * 0.013 - phase * 0.7) * amp * 0.4
        + Math.sin(x * 0.028 + phase * 1.6) * amp * 0.18;   // 细密高频波纹
    }
    function drawFlow() {
      var lines = small ? 6 : 11;          // 更密的水纹带
      var span = 1 / (lines + 1);
      for (var li = 0; li < lines; li++) {
        var baseY = H * (span * (li + 1));
        var phase = t * 0.006 + li * 1.1;
        var amp = 7 + (li % 4) * 3;        // 波幅错落
        // 主水纹(暗)
        ctx.beginPath();
        for (var x = 0; x <= W; x += 10) {
          var y = waveY(x, baseY, phase, amp);
          if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.strokeStyle = ink(0.045);
        ctx.lineWidth = 1;
        ctx.stroke();
        // 高光线(亮,向上错位 1.5px,模拟波峰反光)—— 波光粼粼
        ctx.beginPath();
        for (var x2 = 0; x2 <= W; x2 += 10) {
          var y2 = waveY(x2, baseY - 1.5, phase + 0.25, amp);
          if (x2 === 0) ctx.moveTo(x2, y2); else ctx.lineTo(x2, y2);
        }
        ctx.strokeStyle = isDark() ? 'rgba(160,225,218,0.05)' : 'rgba(255,255,255,0.14)';
        ctx.lineWidth = 0.7;
        ctx.stroke();
      }
    }

    /* ---------- 荷叶 / 睡莲 / 荷花(轻微浮动) ---------- */
    var LILY_N = reduce ? 2 : (small ? 3 : 5);
    var lilies = [];
    for (var m2 = 0; m2 < LILY_N; m2++) {
      lilies.push({
        x: rand(0.08, 0.92) * W,
        y: rand(0.1, 0.9) * H,
        r: rand(18, 40),
        flower: Math.random() < 0.45,      // 部分带花
        bobA: rand(0, Math.PI * 2),        // 浮动相位
        bobS: rand(0.008, 0.016),          // 浮动速度
        drift: rand(-0.06, 0.06)           // 缓慢漂移
      });
    }
    function drawLilies() {
      for (var i = 0; i < lilies.length; i++) {
        var l = lilies[i];
        l.bobA += l.bobS;
        // 缓慢漂移 + 边界回绕
        l.x += l.drift; l.y += Math.sin(l.bobA) * 0.12;
        if (l.x < -50) l.x = W + 50; if (l.x > W + 50) l.x = -50;
        var bob = Math.sin(l.bobA) * 2;    // 上下浮动
        var r = l.r;
        ctx.save();
        ctx.translate(l.x, l.y + bob);
        // 荷叶:圆盘带一个缺口(睡莲叶的经典 V 形切口)
        ctx.beginPath();
        var notch = l.bobA;                // 缺口方向随浮动微转
        ctx.arc(0, 0, r, notch + 0.5, notch - 0.5);
        ctx.lineTo(0, 0);
        ctx.closePath();
        ctx.fillStyle = ink(0.14);
        ctx.fill();
        // 叶脉(几条淡线)
        ctx.strokeStyle = ink(0.08);
        ctx.lineWidth = 0.8;
        for (var v = 0; v < 5; v++) {
          var ang = notch + 0.7 + v * (2 * Math.PI - 1.4) / 5;
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(Math.cos(ang) * r * 0.9, Math.sin(ang) * r * 0.9);
          ctx.stroke();
        }
        // 荷花 / 睡莲花(部分叶子上)
        if (l.flower) {
          var fr = r * 0.42;
          ctx.translate(-r * 0.1, -r * 0.1);
          for (var p = 0; p < 6; p++) {
            var pa = p * Math.PI / 3 + l.bobA * 0.3;
            ctx.beginPath();
            ctx.ellipse(Math.cos(pa) * fr * 0.5, Math.sin(pa) * fr * 0.5,
                        fr * 0.55, fr * 0.22, pa, 0, Math.PI * 2);
            ctx.fillStyle = ink(0.12);
            ctx.fill();
          }
          // 花心
          ctx.beginPath();
          ctx.arc(0, 0, fr * 0.28, 0, Math.PI * 2);
          ctx.fillStyle = ink(0.20);
          ctx.fill();
        }
        ctx.restore();
      }
    }

    /* ---------- 雨涟漪 ---------- */
    var ripples = [];
    var rainTimer = 0;
    function spawnRipple(intensity) {
      intensity = intensity || 0.4;
      ripples.push({
        x: rand(0.05, 0.95) * W,
        y: rand(0.05, 0.95) * H,
        r: 1,
        max: rand(24, 52) * (0.7 + intensity * 0.6),   // 雨大涟漪大
        grow: 0.04 + intensity * 0.03,                 // 雨大扩散快
        life: 1
      });
      if (ripples.length > 40) ripples.shift();
    }
    function drawRipples() {
      for (var i = ripples.length - 1; i >= 0; i--) {
        var p = ripples[i];
        p.life -= 0.012;
        if (p.life <= 0) { ripples.splice(i, 1); continue; }
        p.r += (p.max - p.r) * (p.grow || 0.05);
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
    // 降雨强度随时间起伏:两条不同周期的正弦叠加 -> 时而大时而小,偶有骤雨
    function rainIntensity() {
      var slow = (Math.sin(t * 0.004) + 1) / 2;        // 慢周期(~26s)大势
      var fast = (Math.sin(t * 0.017 + 1.3) + 1) / 2;  // 快周期叠出骤雨
      return 0.15 + slow * 0.6 + fast * 0.25;          // 0.15 ~ 1.0
    }
    function loop() {
      if (!running) { raf = 0; return; }
      t++;
      ctx.clearRect(0, 0, W, H);
      drawFlow();                                      // 水流波动(底层)
      // 雨:强度越高,落点越密(间隔越短)。强度低时零星,高时成片
      var intensity = rainIntensity();
      rainTimer++;
      var gap = 90 - intensity * 78;                   // 强度 1 时约每 12 帧,0.15 时约每 78 帧
      if (rainTimer > gap) {
        var drops = intensity > 0.7 ? 2 : 1;           // 骤雨时一次落多滴
        for (var d = 0; d < drops; d++) spawnRipple(intensity);
        rainTimer = 0;
      }
      drawRipples();
      drawLilies();                                    // 荷叶浮动(在鱼之下,水面之上)
      for (var i = 0; i < fish.length; i++) drawFish(fish[i], t);
      for (var k = 0; k < realFish.length; k++) drawRealisticFish(realFish[k]);
      raf = requestAnimationFrame(loop);
    }

    if (!reduce) { running = true; loop(); }
    else {
      // 静止:画一帧(鱼+荷叶),不动
      drawLilies();
      for (var i = 0; i < fish.length; i++) drawFish(fish[i], 0);
      for (var k = 0; k < realFish.length; k++) drawRealisticFish(realFish[k]);
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
