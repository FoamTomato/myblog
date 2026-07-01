#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从腾讯云 COS 的 posts/ 前缀拉取 markdown 文章到 source/_posts,带三层去重:
  1) 增量:对比 .cos-sync-state.json 里记录的 key->ETag,只拉新增/变更的对象
  2) 内容级:对拉下来的正文算 sha256,与已入库文章(及本轮已写入)比对,相同则跳过
  3) 标题冲突:解析 front-matter 的 title,与现有文章标题撞车时给文件名加后缀

环境变量(GitHub Actions 注入):
  COS_SECRET_ID / COS_SECRET_KEY  子用户只读密钥
  COS_REGION   默认 ap-hongkong
  COS_BUCKET   默认 xiaohang-1403701833
  COS_PREFIX   默认 posts/

退出码 0。是否有新增通过 stdout 的 "CHANGED=1/0" 供 workflow 判断。
"""
import os, sys, re, json, hashlib, io

from qcloud_cos import CosConfig, CosS3Client

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POSTS_DIR = os.path.join(ROOT, 'source', '_posts')
STATE_FILE = os.path.join(ROOT, '.cos-sync-state.json')

REGION = os.environ.get('COS_REGION', 'ap-hongkong')
BUCKET = os.environ.get('COS_BUCKET', 'xiaohang-1403701833')
PREFIX = os.environ.get('COS_PREFIX', 'posts/')
SID = os.environ['COS_SECRET_ID']
SKEY = os.environ['COS_SECRET_KEY']


def log(m):
    print(m, flush=True)


def load_state():
    if os.path.exists(STATE_FILE):
        try:
            return json.load(open(STATE_FILE, encoding='utf-8'))
        except Exception:
            pass
    return {'objects': {}}  # key -> {etag, sha256, filename}


def save_state(state):
    json.dump(state, open(STATE_FILE, 'w', encoding='utf-8'),
              ensure_ascii=False, indent=2, sort_keys=True)


def body_sha256(text):
    """去掉 front-matter 后对正文算 hash,避免仅 date/updated 改动被当成内容变化。"""
    m = re.match(r'^---\n.*?\n---\n?(.*)$', text, re.S)
    body = m.group(1) if m else text
    return hashlib.sha256(body.strip().encode('utf-8')).hexdigest()


def parse_title(text):
    m = re.match(r'^---\n(.*?)\n---', text, re.S)
    if not m:
        return None
    tm = re.search(r'^title:\s*["\']?(.+?)["\']?\s*$', m.group(1), re.M)
    return tm.group(1).strip() if tm else None


def existing_index():
    """扫已入库文章 -> (正文 hash 集合, 标题->文件名, 文件名集合)。"""
    hashes, titles, names = set(), {}, set()
    if not os.path.isdir(POSTS_DIR):
        os.makedirs(POSTS_DIR, exist_ok=True)
        return hashes, titles, names
    for fn in os.listdir(POSTS_DIR):
        if not fn.endswith('.md'):
            continue
        names.add(fn)
        try:
            t = open(os.path.join(POSTS_DIR, fn), encoding='utf-8').read()
        except Exception:
            continue
        hashes.add(body_sha256(t))
        ti = parse_title(t)
        if ti:
            titles.setdefault(ti, fn)
    return hashes, titles, names


def safe_filename(key, title, used_names):
    """由 COS key 的 basename 生成文件名;标题/文件名冲突时加数字后缀。"""
    base = os.path.basename(key)
    if not base.endswith('.md'):
        base += '.md'
    stem, ext = base[:-3], '.md'
    cand = base
    i = 1
    while cand in used_names:
        cand = f'{stem}-{i}{ext}'
        i += 1
    return cand


def list_cos_objects(client):
    """分页列出 PREFIX 下所有 .md 对象 -> [(key, etag)]。"""
    out = []
    marker = ''
    while True:
        resp = client.list_objects(Bucket=BUCKET, Prefix=PREFIX,
                                   Marker=marker, MaxKeys=1000)
        for c in resp.get('Contents', []):
            key = c['Key']
            if key.endswith('/') or not key.lower().endswith('.md'):
                continue
            out.append((key, c['ETag'].strip('"')))
        if resp.get('IsTruncated') == 'true':
            marker = resp.get('NextMarker', '')
        else:
            break
    return out


def main():
    cfg = CosConfig(Region=REGION, SecretId=SID, SecretKey=SKEY, Scheme='https')
    client = CosS3Client(cfg)

    state = load_state()
    seen = state.get('objects', {})
    ex_hashes, ex_titles, ex_names = existing_index()

    objs = list_cos_objects(client)
    log(f'COS posts/ 共 {len(objs)} 个 md 对象')

    changed = 0
    skipped_unchanged = skipped_dup = 0
    new_seen = {}

    for key, etag in objs:
        prev = seen.get(key)
        # 第 1 层:ETag 没变 -> 增量跳过
        if prev and prev.get('etag') == etag:
            new_seen[key] = prev
            skipped_unchanged += 1
            continue

        resp = client.get_object(Bucket=BUCKET, Key=key)
        text = resp['Body'].get_raw_stream().read().decode('utf-8')
        h = body_sha256(text)

        # 第 2 层:内容 hash 命中已有 -> 内容级去重
        if h in ex_hashes:
            log(f'  [dup-content] {key} 正文与已有文章相同,跳过')
            new_seen[key] = {'etag': etag, 'sha256': h,
                             'filename': (prev or {}).get('filename')}
            skipped_dup += 1
            continue

        # 第 3 层:标题冲突 -> 文件名加后缀(不覆盖已有不同内容的同名/同标题)
        title = parse_title(text)
        # 若该 key 之前已写过某文件名,优先复用它(更新场景,原地覆盖)
        fn = (prev or {}).get('filename')
        if fn and fn in ex_names:
            target = fn  # 覆盖更新
        else:
            fn = safe_filename(key, title, ex_names)
            target = fn
            ex_names.add(fn)

        open(os.path.join(POSTS_DIR, target), 'w', encoding='utf-8').write(text)
        ex_hashes.add(h)
        if title:
            ex_titles.setdefault(title, target)
        new_seen[key] = {'etag': etag, 'sha256': h, 'filename': target}
        log(f'  [write] {key} -> source/_posts/{target}'
            + (f'  (title="{title}")' if title else ''))
        changed += 1

    state['objects'] = new_seen
    save_state(state)

    log(f'\n新增/更新 {changed} 篇 | 增量跳过 {skipped_unchanged} | 内容去重 {skipped_dup}')
    print(f'CHANGED={1 if changed else 0}')
    # 供 GitHub Actions 读取
    gh_out = os.environ.get('GITHUB_OUTPUT')
    if gh_out:
        with open(gh_out, 'a') as f:
            f.write(f'changed={1 if changed else 0}\n')
            f.write(f'count={changed}\n')


if __name__ == '__main__':
    main()
