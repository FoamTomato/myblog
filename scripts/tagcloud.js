/**
 * 自定义 Hexo tag 插件: {% tagcloud %}
 *
 * 目标: 只展示最重要的 TOP-N 标签(按文章数 = tag.length 降序),
 *       字号严格按"频率占比"映射 —— 高频标签明显更大, 形成真正的词云;
 *       纯青绿水墨色系, 无随机花色。
 *
 * 用法(在 source/tags/index.md 里, 去掉 type:tags 后):
 *   {% tagcloud %}                 // 默认 top 40
 *   {% tagcloud 30 %}              // 只取 top 30
 *   {% tagcloud 30 1.0 3.2 %}      // top 30, 最小 1.0em, 最大 3.2em
 *
 * 参数(全部可选, 位置参数):
 *   args[0] = topN       取频率最高的前 N 个标签, 默认 40
 *   args[1] = minSize    最小字号(em), 默认 1.0
 *   args[2] = maxSize    最大字号(em), 默认 3.4
 *
 * 输出: 一段 HTML 字符串, 直接嵌入 page.content(由 default-page.pug 的
 *       `!= page.content` 原样输出, 不转义)。
 *
 * 持久性: 本文件在仓库自有 scripts/ 目录, hexo 启动时自动加载注册,
 *         不依赖 node_modules 内的主题文件, 服务器 npm install 不会覆盖。
 */

'use strict'

hexo.extend.tag.register('tagcloud', function (args) {
  // ---------- 1. 解析参数 ----------
  const topN = Math.max(1, parseInt(args[0], 10) || 40)
  const minSize = parseFloat(args[1]) || 1.0
  const maxSizeRaw = parseFloat(args[2]) || 3.4
  // 保证 max >= min, 防止用户传反
  const maxSize = Math.max(maxSizeRaw, minSize)

  // ---------- 2. 取全部标签 ----------
  // hexo.locals.get('tags') 返回一个 Warehouse Query, 元素是 Tag 对象:
  //   .name(名称) .path(相对链接) .length(该标签下文章数) .permalink
  // 用 toArray() 落成普通数组, 只保留有文章的标签(length > 0)。
  const tagsQuery = this.site && this.site.tags ? this.site.tags : hexo.locals.get('tags')

  let tags = []
  if (tagsQuery && typeof tagsQuery.toArray === 'function') {
    tags = tagsQuery.toArray()
  } else if (Array.isArray(tagsQuery)) {
    tags = tagsQuery.slice()
  }

  tags = tags.filter(t => t && t.name && t.length > 0)

  // 没有任何标签: 返回空占位, 不报错
  if (tags.length === 0) {
    return '<div class="tagcloud-empty" style="text-align:center;color:#0a3a42;opacity:.6;">暂无标签</div>'
  }

  // ---------- 3. 按频率(文章数)降序, 取 top N ----------
  tags.sort((a, b) => {
    if (b.length !== a.length) return b.length - a.length
    // 频率相同时按名称稳定排序, 保证每次生成结果一致(无随机)
    return String(a.name).localeCompare(String(b.name), 'zh-Hans-CN')
  })

  const top = tags.slice(0, topN)

  // ---------- 4. 频率占比 -> 字号(em) ----------
  // 与主题原算法(按去重排名索引)不同: 这里用真实频率的线性归一化,
  // 让"文章数越多的标签字越大"的差异真正体现出频率占比。
  const counts = top.map(t => t.length)
  const maxCount = Math.max.apply(null, counts)
  const minCount = Math.min.apply(null, counts)
  const span = maxCount - minCount // 可能为 0(全部标签文章数相同)

  // 轻微的伽马压缩, 让中低频标签不至于全部挤在最小字号,
  // 同时高频依然突出。gamma < 1 抬升中间值; 用 0.75 视觉更均衡。
  const GAMMA = 0.75

  const escapeHtml = str => String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')

  // 站点根路径前缀(处理 root 非 "/" 的情况, 如子目录部署)
  const root = (hexo.config.root || '/').replace(/\/+$/, '/') // 保留末尾斜杠
  const buildUrl = tag => {
    // Tag.path 形如 "tags/xxx/"; 拼上 root。permalink 也可用但含域名, 站内用相对更稳。
    const p = String(tag.path || '').replace(/^\/+/, '')
    return escapeHtml((root.endsWith('/') ? root : root + '/') + p)
  }

  // ---------- 5. 生成词云 HTML ----------
  const items = top.map((tag, i) => {
    let ratio
    if (span === 0) {
      ratio = 1 // 所有标签同频 -> 统一取最大字号(视觉上仍是词云而非全小字)
    } else {
      ratio = (tag.length - minCount) / span // 0..1 线性频率占比
      ratio = Math.pow(ratio, GAMMA)          // 伽马压缩
    }

    const fontSize = (minSize + (maxSize - minSize) * ratio).toFixed(3)

    // 青绿水墨色系: 同一色相(teal), 频率越高颜色越深越实, 越低越浅。
    // 频率的"淡浅"只用 color 明度表达(不用 opacity, 以免与入场动画的
    // opacity 打架, 详见 tagcloud.css)。无随机色。
    // 高频端 ~ rgb(10,58,66)=#0a3a42(深青墨); 低频端 ~ rgb(120,180,185)(浅青)。
    const r = Math.round(120 - 110 * ratio)  // 120 -> 10
    const g = Math.round(180 - 122 * ratio)  // 180 -> 58
    const b = Math.round(185 - 119 * ratio)  // 185 -> 66

    // 权重也随频率增强, 强化词云层次
    const weight = ratio > 0.66 ? 700 : (ratio > 0.33 ? 600 : 500)

    // 频率分 5 档(0..4), 供深色模式 CSS 按档位给浅青色阶(见 tagcloud.css)
    const level = Math.min(4, Math.floor(ratio * 5))

    const name = escapeHtml(tag.name)
    const url = buildUrl(tag)
    const count = tag.length

    // 每个标签一个 <a>, 内联 style 承载字号/颜色, class 供 CSS/JS 增强。
    // title 与 aria-label 带文章数, 便于可访问性与悬浮提示。
    // data-count 供 JS(如需)或调试使用。
    return (
      '<a class="tagcloud-item"'
      + ' data-tc-level="' + level + '"'
      + ' href="' + url + '"'
      + ' style="font-size:' + fontSize + 'em;color:rgb(' + r + ',' + g + ',' + b + ');font-weight:' + weight + ';--tc-delay:' + (i * 18) + 'ms;"'
      + ' title="' + name + ' · ' + count + ' 篇"'
      + ' aria-label="' + name + ', ' + count + ' 篇文章">'
      + '<span class="tagcloud-name">' + name + '</span>'
      + '<sup class="tagcloud-count">' + count + '</sup>'
      + '</a>'
    )
  })

  return '<div class="tagcloud-wrap" role="navigation" aria-label="标签词云">'
    + items.join('')
    + '</div>'
}, { async: false })
