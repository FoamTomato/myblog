/**
 * 自动给「自定义注入资源」加内容哈希版本号 —— 破浏览器缓存
 *
 * 背景:Butterfly 的 inject.head / inject.bottom 是原样注入的静态字符串,
 *   主题自带资源带 ?v=5.5.4,但我们注入的 custom-archive.css / aurora-bg.css /
 *   tagcloud.css / pond.js / interactions.js 不带版本号 → 改动后浏览器仍用旧缓存,
 *   表现为"线上没变化"(实际已部署)。
 *
 * 方案:注册 after_render:html 过滤器,在最终 HTML 里把这些 URL 追加 ?v=<hash8>。
 *   hash 基于 source/ 下对应文件的内容(md5 前 8 位)。
 *   → 文件内容一变,hash 变,URL 变,浏览器自动重新拉取;内容不变则 hash 稳定,继续命中缓存。
 *   完全免手动维护版本号。
 *
 * 持久性:仓库自有 scripts/,hexo 启动自动加载,不受 npm install 影响。
 */
'use strict'

const fs = require('fs')
const path = require('path')
const crypto = require('crypto')

// 需要加版本号的自定义资源(相对站点根的路径 -> source 下的真实文件)
const ASSETS = [
  '/css/custom-archive.css',
  '/css/aurora-bg.css',
  '/css/tagcloud.css',
  '/js/pond.js',
  '/js/interactions.js'
]

// 缓存已算过的 hash(单次 generate 内多次调用不重复读盘)
const hashCache = {}

function hashOf(urlPath) {
  if (hashCache[urlPath] !== undefined) return hashCache[urlPath]
  let h = ''
  try {
    // source 目录下的真实文件,如 /css/aurora-bg.css -> source/css/aurora-bg.css
    const file = path.join(hexo.source_dir, urlPath.replace(/^\//, ''))
    const buf = fs.readFileSync(file)
    h = crypto.createHash('md5').update(buf).digest('hex').slice(0, 8)
  } catch (e) {
    // 文件读不到就不加版本号(退化为原样,不报错)
    h = ''
  }
  hashCache[urlPath] = h
  return h
}

hexo.extend.filter.register('after_render:html', function (html) {
  ASSETS.forEach(function (asset) {
    const h = hashOf(asset)
    if (!h) return
    // 只替换尚未带 ?v= 的引用;转义特殊字符,匹配 href="asset" 或 src="asset"
    const esc = asset.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    // 匹配 ="/css/xxx.css" 且后面不是 ?(避免重复加)
    const re = new RegExp('(["\'(])' + esc + '(?![?\\w.-])', 'g')
    html = html.replace(re, '$1' + asset + '?v=' + h)
  })
  return html
}, 20)
