#!/usr/bin/env python3
"""Build a pinned, filtered Vietnamese quote catalog; never run at app runtime."""
import hashlib
import json
import re
import unicodedata
import urllib.request
from pathlib import Path

REVISION = 'd41ef22a98435fd3cbd75298463872d038c658e4'
ROOT = Path(__file__).resolve().parent.parent
BASE = f'https://raw.githubusercontent.com/trananhtung/danh-ngon/{REVISION}/'
SOURCE = f'https://github.com/trananhtung/danh-ngon/blob/{REVISION}/data/quotes.json'
TOPICS = {'cuoc-song', 'tri-tue', 'giao-duc', 'thoi-gian', 'gia-dinh', 'tinh-ban', 'tam-hon'}


def normalize(text):
    return ' '.join(unicodedata.normalize('NFC', text).replace('Ð', 'Đ').split())


def select_quotes(data):
    selected = []
    seen = set()
    for item in data:
        text = normalize(item.get('vi', ''))
        author = normalize(item.get('author', ''))
        if not 40 <= len(text) <= 130 or not 2 <= len(author) <= 38:
            continue
        if not any(c in 'ăâđêôơưĂÂĐÊÔƠƯ' or '\u1ea0' <= c <= '\u1ef9' for c in text):
            continue
        if text == item.get('en') or any(c in text for c in ['[', ']', '{', '}', '<', '>', 'http', 'www.', '…']):
            continue
        english = normalize(item.get('en', ''))
        if len(english) > 15 and english[:25].casefold() in text.casefold():
            continue
        if any('\u4e00' <= c <= '\u9fff' for c in text):
            continue
        if not set(item.get('topics', [])) & TOPICS:
            continue
        # Prefer complete, general life reflections over fragments or gender stereotypes.
        if any(word in text.casefold() for word in ['đàn bà', 'đàn ông', 'phụ nữ', 'giết', 'ngu dốt']):
            continue
        if author in ['Luôn mỉm cười với cuộc sống', 'Sưu tầm', 'Unknown']:
            continue
        key = re.sub(r'[^\w]+', '', text.casefold())
        if key in seen:
            continue
        seen.add(key)
        selected.append({'id': f'danh-ngon-{item["id"]}', 'text': text, 'author': author, 'sourceURL': SOURCE})
    selected.sort(key=lambda q: hashlib.sha256(('amlich:' + q['id']).encode()).hexdigest())
    if len(selected) < 1000:
        raise ValueError(f'Expected at least 1000 eligible quotes, got {len(selected)}')
    return sorted(selected[:1000], key=lambda q: int(q['id'].rsplit('-', 1)[1]))


def main():
    with urllib.request.urlopen(BASE + 'data/quotes.json', timeout=30) as response:
        raw = response.read()
    with urllib.request.urlopen(BASE + 'LICENSE', timeout=30) as response:
        license_text = response.read().decode('utf-8')
    quotes = select_quotes(json.loads(raw))
    catalog = {
        'schemaVersion': 1,
        'source': SOURCE,
        'sourceRevision': REVISION,
        'sourceSHA256': hashlib.sha256(raw).hexdigest(),
        'license': 'MIT, as declared by the upstream compilation; original quotations retain their source rights.',
        'note': 'Length/language/topic filters and deduplication; translations and author attributions are inherited from upstream, not individually verified.',
        'quotes': quotes,
    }
    resources = ROOT / 'CalendarXLib/Sources/Resources'
    (resources / 'daily_quotes.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    (resources / 'danh-ngon-LICENSE.txt').write_text(license_text)
    print(f'Imported {len(quotes)} Vietnamese quotes from {REVISION}')


if __name__ == '__main__':
    main()
