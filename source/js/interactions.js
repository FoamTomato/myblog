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
    // 归档页文章多,进入动画用 IO 触发(替代纯 CSS 的固定延迟,更自然)。
    // 关键兜底:阈值放宽 + 定时器强制显示。若 IO 因懒加载图片高度未定、
    // pjax 时机等原因迟迟不触发,1.2s 后强制给所有卡片加 .arc-in,
    // 确保永远不会因动画链路故障而整页空白。
    if (!reduce && 'IntersectionObserver' in window) {
      var revealAll = function () {
        cards.forEach(function (c) { c.classList.add('arc-in'); });
      };
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            e.target.classList.add('arc-in');
            io.unobserve(e.target);
          }
        });
      }, { threshold: 0.01, rootMargin: '0px 0px 0px 0px' });
      cards.forEach(function (c) { c.classList.add('arc-reveal'); io.observe(c); });
      // 兜底:1.2s 后无论 IO 是否触发,全部显现(幂等,arc-in 已加则无副作用)
      setTimeout(revealAll, 1200);
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

    // 白云晕染拖尾:鼠标过处像晕开一片淡淡的白云飘过 —— 柔白团向外洇开、
    // 大小随机,浓度很淡,缓缓扩散再慢慢化去,轻盈通透。
    var dabs = [];              // 云团池(每团 = 一次落笔洇开的白云)
    var lastX = 0, lastY = 0, lastT = 0, rafInk = 0, hasLast = false;
    // 浅白:两种模式都用近白,靠 screen/lighter 混合提亮成云(深色底更透亮)。
    function cloudColor(a) {
      var dark = document.documentElement.getAttribute('data-theme') === 'dark';
      return dark
        ? 'rgba(235, 250, 250,' + a + ')'
        : 'rgba(255, 255, 255,' + a + ')';   // 纯白云
    }

    // 沿轨迹晕一团白云:大而软,随机扩散大小(辐射大),浓度极淡
    function dab(x, y, speed) {
      // 核心半径很大(云是大团、辐射极广);慢移更大,快移略小
      var base = 70 - Math.min(20, speed * 0.24);
      dabs.push({
        // 位置大幅随机抖开:落点不紧贴轨迹,零散点染,避免连成跟随指针的亮带
        x: x + (Math.random() - 0.5) * 46,
        y: y + (Math.random() - 0.5) * 46,
        r: base * (0.8 + Math.random() * 0.5),      // 初始云核
        maxR: base * (4.0 + Math.random() * 3.5),   // 辐射再加 + 随机差异大(大小随机)
        // 极极淡的白:单团几乎无法察觉,靠密集叠加透出一抹若有若无的轻云
        a: 0.008 + Math.random() * 0.014,
        life: 1,
        // rise = 浮现进度 0→1:云缓缓显形而非一出现就最亮,
        // 等它最浓时鼠标早已走远 → 消除"白斑紧跟指针"的移动感
        rise: 0,
        riseSpeed: 0.012 + Math.random() * 0.01,    // 浮现很慢(~1.5s 才到最浓)
        decay: 0.0013 + Math.random() * 0.0010,     // 化去极慢(约 15~18s),悠然弥散
        spread: 0.25 + Math.random() * 0.3          // 洇开更慢:缓缓铺展到极大辐射
      });
      if (dabs.length > 240) dabs.splice(0, dabs.length - 240);
    }

    function render() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      // lighter 叠加:多团淡白累积成更亮更实的云,自然连成一片(而非硬边圆)
      ctx.globalCompositeOperation = 'lighter';
      for (var i = dabs.length - 1; i >= 0; i--) {
        var d = dabs[i];
        d.life -= d.decay;
        if (d.life <= 0) { dabs.splice(i, 1); continue; }
        // 洇开:半径向 maxR 缓慢逼近(先快后慢,像云慢慢舒展)
        if (d.r < d.maxR) d.r += (d.maxR - d.r) * 0.02 + d.spread;
        // 淡入:rise 缓缓从 0 涨到 1(云慢慢浮现,不紧跟指针);淡出:life 减到 0。
        if (d.rise < 1) d.rise += d.riseSpeed;
        var fadeIn = d.rise < 1 ? d.rise : 1;
        var fadeOut = d.life;                        // 线性淡出,配合极小 decay 很缓
        var al = d.a * fadeIn * fadeOut;
        // 大幅羽化的径向渐变,无明显边界 = 云的通透质感
        var g = ctx.createRadialGradient(d.x, d.y, 0, d.x, d.y, d.r);
        g.addColorStop(0, cloudColor(al));
        g.addColorStop(0.4, cloudColor(al * 0.5));
        g.addColorStop(1, cloudColor(0));
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(d.x, d.y, d.r, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.globalCompositeOperation = 'source-over';
      if (dabs.length) {
        rafInk = requestAnimationFrame(render);
      } else {
        rafInk = 0;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
    }

    var acc = 0;   // 累计移动距离:攒够一段才点染一团,落点稀疏
    window.addEventListener('pointermove', function (ev) {
      var now = ev.timeStamp || performance.now();
      if (!hasLast) { lastX = ev.clientX; lastY = ev.clientY; lastT = now; hasLast = true; return; }
      var dx = ev.clientX - lastX, dy = ev.clientY - lastY, dt = now - lastT || 16;
      var dist = Math.sqrt(dx * dx + dy * dy);
      var speed = dist / dt * 16;            // 归一化速度
      if (dist < 0.5) { lastT = now; return; }

      // 稀疏点染:每累计移动 ~55px 才在附近随机晕一团(不再沿轨迹密集撒成亮带)。
      // 配合 dab 里的大位置抖动 + 慢淡入,云是零散、缓缓浮现的,无跟随指针的移动感。
      acc += dist;
      while (acc >= 55) {
        acc -= 55;
        dab(ev.clientX, ev.clientY, speed);
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

/* ============================================================
 * 失效图片 → 随机水塘 SVG 插画兜底
 * 任何 <img> 加载失败时,随机换成 covers/ 里的一张水塘 SVG,
 * 与主题统一,避免出现裂图/占位灰块。用捕获阶段监听 error,
 * 覆盖率优于逐个绑 onerror(含 pjax 后新插入的图)。
 * ============================================================ */
(function () {
  'use strict';
  var COVERS = [
    '/img/covers/pond-01-fish.svg',
    '/img/covers/pond-02-ripple.svg',
    '/img/covers/pond-03-lotus.svg',
    '/img/covers/pond-04-reeds.svg',
    '/img/covers/pond-05-koi.svg',
    '/img/covers/pond-06-mountain.svg',
    '/img/covers/pond-07-empty.svg'
  ];
  function pick() { return COVERS[Math.floor(Math.random() * COVERS.length)]; }
  document.addEventListener('error', function (e) {
    var img = e.target;
    if (!img || img.tagName !== 'IMG') return;
    // 已经是兜底 SVG 就不再替换,避免死循环
    if (img.dataset.fallbackApplied) return;
    var src = img.getAttribute('src') || '';
    if (src.indexOf('/img/covers/pond-') !== -1) { img.dataset.fallbackApplied = '1'; return; }
    img.dataset.fallbackApplied = '1';
    img.src = pick();
  }, true);  // 捕获阶段:img 的 error 不冒泡,必须用 capture
})();
