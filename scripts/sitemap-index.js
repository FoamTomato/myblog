/* global hexo */
'use strict'

/*
 * 自定义 sitemap 生成器:索引 + 按年份分片(增量滚动)。
 *
 * 产物:
 *   sitemap.xml            <- sitemapindex,指向 sitemap-<year>.xml
 *   sitemap-<year>.xml     <- 该年文章 + (最新年份额外含 分类/标签/静态页)
 *   baidusitemap.xml       <- 百度 sitemapindex
 *   baidusitemap-<year>.xml<- 百度子图(仅文章,无 changefreq/priority)
 *
 * 注:Bing 用与谷歌相同的标准 sitemap.xml,不单独产 bing 图(避免冗余副本)。
 *
 * 增量语义:索引里每个子图的 <lastmod> = 该子图内最新的文章时间
 * (真实发布日 date 为准,有手写 updated 且更晚时取 updated)。
 * 改/发一篇某年的文章,只有那一年的子图 lastmod 变化,
 * 搜索引擎按 lastmod 只重抓变化的子图,实现"按平台规则自动增量"。
 */

hexo.extend.generator.register('sitemap_index', function (locals) {
  const cfg = this.config
  const opt = cfg.sitemap_index || {}
  const base = String(cfg.url || '').replace(/\/+$/, '')

  const indexPath = opt.index || 'sitemap.xml'
  const childTpl = opt.child || 'sitemap-{year}.xml'
  const baiduIndexPath = opt.baidu_index || 'baidusitemap.xml'
  const baiduChildTpl = opt.baidu_child || 'baidusitemap-{year}.xml'
  const includeTags = opt.include_tags !== false
  const includeCategories = opt.include_categories !== false
  const includePages = opt.include_pages !== false

  const esc = (s) =>
    String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;')

  // 拼绝对 URL:兼容 permalink 生成的相对 path
  // 统一规范化:去掉尾部 index.html(与页面 canonical 一致),
  // 并对中文/全角字符做百分号编码(sitemap 协议要求 RFC-3986 编码,
  // 也保证与 <link rel="canonical"> 输出的编码形式完全一致)
  const abs = (p) => {
    let s = String(p).replace(/index\.html$/, '')
    if (!/^https?:\/\//i.test(s)) s = base + '/' + s.replace(/^\/+/, '')
    return encodeURI(s)
  }

  // 只允许真正的 HTML 页面进 sitemap:
  // 排除被 Hexo 误当作 page 的 css/js 等静态资源,以及搜索引擎验证文件
  const isIndexablePage = (p) => {
    const s = String(p).replace(/index\.html$/, '')
    if (!/(\/|\.html)$/.test(s) && s !== '') return false
    if (/(baidu_verify|google[0-9a-f]+\.html|BingSiteAuth)/i.test(s)) return false
    // IndexNow key 文件(<32位hex>.txt)不进 sitemap
    if (/^\/?[0-9a-f]{8,}\.txt$/i.test(s)) return false
    return true
  }

  const toISO = (m) => {
    // m 是 moment 对象(Hexo 注入)或可被 new Date 解析的值。
    // 优先用 moment.format 保留本地时区:否则 toISOString() 转 UTC 会把
    // 东八区的 'YYYY-MM-DD 00:00' 拉回前一天,导致 lastmod 全站偏一天。
    if (m && typeof m.format === 'function') return m.format('YYYY-MM-DDTHH:mm:ssZ')
    if (m && typeof m.toISOString === 'function') return m.toISOString()
    if (m && typeof m.toDate === 'function') return m.toDate().toISOString()
    return null
  }
  const ymd = (iso) => (iso ? iso.slice(0, 10) : null)

  // ---- 1) 收集文章,按年份归组 ----
  const byYear = {} // year -> [{loc, lastmodISO}]
  const posts = locals.posts.sort('-date').toArray()
  let latestYear = null

  const pushEntry = (year, loc, lastmodISO) => {
    if (!byYear[year]) byYear[year] = []
    byYear[year].push({ loc, lastmodISO })
  }

  posts.forEach((post) => {
    if (post.sitemap === false) return
    // lastmod 取真实发布日期 date 为基准;仅当存在“真实的、晚于 date 的 updated”
    // (front-matter 手写)才用 updated。配合 updated_option:'date',没手写 updated
    // 的文章 post.updated == post.date,不会再被 mtime 污染成部署当天。
    const pubISO = toISO(post.date)
    const updISO = toISO(post.updated)
    const iso = (updISO && (!pubISO || updISO > pubISO)) ? updISO : pubISO
    const year = pubISO ? pubISO.slice(0, 4) : (iso ? iso.slice(0, 4) : 'undated')
    if (latestYear === null || year > latestYear) latestYear = year
    pushEntry(year, abs(post.path), iso)
  })

  if (posts.length === 0) return []
  if (latestYear === null) latestYear = Object.keys(byYear).sort().pop()

  // ---- 2) 非文章页(分类/标签/静态页)归入最新年份 ----
  const extra = [] // 仅进谷歌图,不进百度图
  const collect = (list) => {
    list.forEach((item) => {
      if (!item.path || !isIndexablePage(item.path)) return
      const iso = toISO(item.updated) || toISO(item.date) || null
      extra.push({ loc: abs(item.path), lastmodISO: iso })
    })
  }
  // 首页(hexo-generator-index 生成,不在 locals.pages 里)
  extra.push({
    loc: base + '/',
    lastmodISO: toISO(posts[0] && (posts[0].updated || posts[0].date))
  })
  if (includeCategories) collect(locals.categories.toArray())
  if (includeTags) collect(locals.tags.toArray())
  if (includePages) collect(locals.pages.toArray().filter((p) => p.sitemap !== false))

  // ---- 3) 渲染 <urlset> ----
  const renderUrlset = (entries, { withMeta }) => {
    const urls = entries.map((e) => {
      let s = '  <url>\n    <loc>' + esc(e.loc) + '</loc>\n'
      const d = ymd(e.lastmodISO)
      if (d) s += '    <lastmod>' + d + '</lastmod>\n'
      if (withMeta) {
        s += '    <changefreq>weekly</changefreq>\n'
        s += '    <priority>0.7</priority>\n'
      }
      return s + '  </url>'
    })
    return '<?xml version="1.0" encoding="UTF-8"?>\n' +
      '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
      urls.join('\n') + '\n</urlset>\n'
  }

  // ---- 4) 渲染 <sitemapindex> ----
  const renderIndex = (children) => {
    const items = children.map((c) => {
      let s = '  <sitemap>\n    <loc>' + esc(abs(c.path)) + '</loc>\n'
      if (c.lastmod) s += '    <lastmod>' + c.lastmod + '</lastmod>\n'
      return s + '  </sitemap>'
    })
    return '<?xml version="1.0" encoding="UTF-8"?>\n' +
      '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
      items.join('\n') + '\n</sitemapindex>\n'
  }

  const routes = []
  const years = Object.keys(byYear).sort() // 升序,索引里旧->新
  const googleChildren = []
  const baiduChildren = []

  years.forEach((year) => {
    // 谷歌子图:该年文章 + (若是最新年)额外页
    let gEntries = byYear[year].slice()
    if (year === latestYear && extra.length) gEntries = gEntries.concat(extra)

    const childPath = childTpl.replace('{year}', year)
    routes.push({ path: childPath, data: renderUrlset(gEntries, { withMeta: true }) })

    const gLast = gEntries
      .map((e) => e.lastmodISO).filter(Boolean).sort().pop()
    googleChildren.push({ path: childPath, lastmod: ymd(gLast) })

    // 百度子图:仅该年文章,无 changefreq/priority
    const bChildPath = baiduChildTpl.replace('{year}', year)
    routes.push({ path: bChildPath, data: renderUrlset(byYear[year], { withMeta: false }) })
    const bLast = byYear[year]
      .map((e) => e.lastmodISO).filter(Boolean).sort().pop()
    baiduChildren.push({ path: bChildPath, lastmod: ymd(bLast) })
  })

  routes.push({ path: indexPath, data: renderIndex(googleChildren) })
  routes.push({ path: baiduIndexPath, data: renderIndex(baiduChildren) })

  return routes
})
