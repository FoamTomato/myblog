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

    /* ---------- 2) 鼠标跟随光晕 ---------- */
    var glow = document.getElementById('cursor-glow');
    if (!glow) {
      glow = document.createElement('div');
      glow.id = 'cursor-glow';
      glow.setAttribute('aria-hidden', 'true');
      document.body.appendChild(glow);
    }
    var gx = window.innerWidth / 2, gy = window.innerHeight / 2, tx = gx, ty = gy, rafGlow = 0;
    function moveGlow() {
      // 缓动跟随(lerp),更丝滑
      gx += (tx - gx) * 0.12;
      gy += (ty - gy) * 0.12;
      glow.style.transform = 'translate3d(' + (gx - 250) + 'px,' + (gy - 250) + 'px,0)';
      if (Math.abs(tx - gx) > 0.5 || Math.abs(ty - gy) > 0.5) {
        rafGlow = requestAnimationFrame(moveGlow);
      } else { rafGlow = 0; }
    }
    window.addEventListener('pointermove', function (ev) {
      tx = ev.clientX; ty = ev.clientY;
      if (!rafGlow) rafGlow = requestAnimationFrame(moveGlow);
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
