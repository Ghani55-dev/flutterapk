import json
import time
import urllib.request
import urllib.error

BASE = 'https://incite-backend.onrender.com/api/v1'

def get(path, params=None):
    url = BASE + path
    if params:
        qs = '&'.join(f"{k}={v}" for k, v in params.items())
        url = f"{url}?{qs}"
    print('GET', url)
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            body = r.read().decode('utf-8')
            print('STATUS', r.status)
            return r.status, json.loads(body)
    except urllib.error.HTTPError as e:
        print('HTTP ERROR', e.code)
        try:
            return e.code, json.loads(e.read().decode('utf-8'))
        except Exception:
            return e.code, None
    except Exception as e:
        print('ERROR', e)
        return None, None

def run():
    # categories
    s, cats = get('/categories/')
    if s != 200:
        print('Categories fetch failed')
        return
    cats_list = cats.get('data') or cats
    print('Categories count', len(cats_list) if isinstance(cats_list, list) else 'N/A')

    # featured
    s, feat = get('/articles/featured/')
    if s != 200:
        print('Featured fetch failed')
    else:
        feat_items = feat.get('data') or feat
        print('Featured count', len(feat_items) if isinstance(feat_items, list) else 'N/A')

    # feed pagination
    def extract_items(obj):
        # obj may be dict or list; support multiple shapes
        if obj is None:
            return []
        if isinstance(obj, list):
            return obj
        if isinstance(obj, dict):
            d = obj.get('data') or obj
            if isinstance(d, list):
                return d
            if isinstance(d, dict):
                for k in ('results', 'items', 'articles'):
                    if k in d and isinstance(d[k], list):
                        return d[k]
                # maybe top-level dict with results
                for k in ('results', 'items', 'articles'):
                    if k in obj and isinstance(obj[k], list):
                        return obj[k]
        return []

    s1, p1 = get('/articles/feed/', {'page': 1, 'page_size': 10})
    if s1 != 200:
        print('Feed page1 failed')
        return
    items1 = extract_items(p1)
    ids1 = [str(x.get('id') or x.get('uuid') or x.get('pk')) for x in items1]
    print('Page1 items', len(ids1))

    s2, p2 = get('/articles/feed/', {'page': 2, 'page_size': 10})
    if s2 != 200:
        print('Feed page2 failed')
        return
    items2 = extract_items(p2)
    ids2 = [str(x.get('id') or x.get('uuid') or x.get('pk')) for x in items2]
    print('Page2 items', len(ids2))

    dup = set(ids1) & set(ids2)
    print('Duplicates between page1 & page2:', len(dup))

    # category filter test
    if isinstance(cats_list, list) and len(cats_list) > 0:
        first = cats_list[0]
        slug = first.get('slug') or first.get('name') or first.get('id')
        print('Testing category filter with', slug)
        s3, pc = get('/articles/feed/', {'page': 1, 'page_size': 10, 'category': slug})
        if s3 == 200:
            itemsc = extract_items(pc)
            print('Category items', len(itemsc))
        else:
            print('Category filter failed', s3)

    # refresh simulation
    print('Refresh simulation: re-fetch page1')
    time.sleep(1)
    s4, p4 = get('/articles/feed/', {'page': 1, 'page_size': 10})
    if s4 == 200:
        items4 = extract_items(p4)
        ids4 = [str(x.get('id') or x.get('uuid') or x.get('pk')) for x in items4]
        print('Refresh items', len(ids4))
        print('Dup with first fetch', len(set(ids1) & set(ids4)))

    # slow network test: perform request with low timeout to simulate failure
    print('Slow network simulation: very short timeout')
    try:
        req = urllib.request.Request(BASE + '/articles/feed/?page=1&page_size=10')
        with urllib.request.urlopen(req, timeout=0.001) as r:
            print('Unexpected success')
    except Exception as e:
        print('Expected timeout/error:', type(e), e)

    print('Smoke tests completed')

if __name__ == '__main__':
    run()
