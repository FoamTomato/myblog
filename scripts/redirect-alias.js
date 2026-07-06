/* global hexo */
'use strict'

/*
 * 老 URL 跳转页生成器(URL 迁移用,静态站的"301")。
 *
 * 文章 front-matter 里声明历史路径:
 *   permalink: performance/mysql-performance-tuning/   <- 新英文规范 URL
 *   redirect_from:
 *     - "2025/08/20/0.6.1-MySQL性能优化全攻略/"          <- 老中文 URL
 *
 * 本脚本在每个老路径生成一个跳转页:
 *   <meta http-equiv="refresh" content="0; url=新URL"> + rel=canonical 指向新 URL
 * Google/百度都把 0 秒 meta refresh 当作永久重定向处理,
 * 老 URL 的收录与权重会合并到新 URL,访客/爬虫到达老链接即刻跳转。
 * 跳转页是纯 route,不进 sitemap(sitemap 只收新 URL)。
 */

hexo.extend.generator.register('redirect_alias', function (locals) {
  const base = String(this.config.url || '').replace(/\/+$/, '')
  const routes = []

  const stub = (target) =>
    '<!DOCTYPE html>\n<html lang="zh-CN">\n<head>\n<meta charset="utf-8">\n' +
    '<title>页面已迁移</title>\n' +
    '<link rel="canonical" href="' + target + '">\n' +
    '<meta http-equiv="refresh" content="0; url=' + target + '">\n' +
    '<script>location.replace("' + target + '")</script>\n' +
    '</head>\n<body>\n<p>本文已迁移至 <a href="' + target + '">' + target + '</a></p>\n' +
    '</body>\n</html>\n'

  locals.posts.forEach((post) => {
    let aliases = post.redirect_from
    if (!aliases) return
    if (!Array.isArray(aliases)) aliases = [aliases]
    // 新规范 URL(英文路径,纯 ASCII;encodeURI 兜底)
    const target = encodeURI(base + '/' + String(post.path).replace(/^\/+/, ''))
    aliases.forEach((a) => {
      const p = String(a).replace(/^\/+/, '').replace(/\/+$/, '') + '/index.html'
      routes.push({ path: p, data: stub(target) })
    })
  })

  // 分类页:category_map 改英文 slug 后,老中文分类 URL 也补跳转
  locals.categories.forEach((cat) => {
    const newPath = String(cat.path).replace(/^\/+/, '')
    const oldPath = 'categories/' + cat.name + '/'
    if (oldPath === newPath) return
    routes.push({ path: oldPath + 'index.html', data: stub(encodeURI(base + '/' + newPath)) })
  })

  return routes
})
