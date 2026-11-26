"""Validate the actual Dart session data without executing Flutter.
Run from the project root: python3 tools/validate_revised_content.py
This does not replace flutter analyze, flutter test, or device QA.
"""
from pathlib import Path
import ast
import collections
import json
import re

ROOT = Path(__file__).resolve().parents[1]
TOKEN = re.compile(r'''\s+|//[^\n]*|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"|0x[0-9A-Fa-f]+|-?\d+(?:\.\d+)?|[A-Za-z_]\w*|[^\s]''')

def parse_constructor(source, offset):
    tokens = [m.group() for m in TOKEN.finditer(source[offset:]) if not m.group().isspace() and not m.group().startswith('//')]
    pos = 0
    def value():
        nonlocal pos
        t = tokens[pos]; pos += 1
        if t == 'const': return value()
        if t[0] in "\"'": return ast.literal_eval(t)
        if t in ('true', 'false'): return t == 'true'
        if re.fullmatch(r'-?\d+(?:\.\d+)?|0x[0-9A-Fa-f]+', t):
            return float(t) if '.' in t else int(t, 0) if t.startswith('0x') else int(t)
        if t == '[':
            items = []
            while tokens[pos] != ']':
                items.append(value())
                if tokens[pos] == ',': pos += 1
            pos += 1
            return items
        if t == '{':
            items = {}
            while tokens[pos] != '}':
                key = value(); assert tokens[pos] == ':'; pos += 1
                items[key] = value()
                if tokens[pos] == ',': pos += 1
            pos += 1
            return items
        if tokens[pos] == '(':
            pos += 1; args = []; named = {}
            while tokens[pos] != ')':
                if pos + 1 < len(tokens) and tokens[pos + 1] == ':':
                    key = tokens[pos]; pos += 2; named[key] = value()
                else: args.append(value())
                if tokens[pos] == ',': pos += 1
            pos += 1
            return {'type': t, 'args': args, **named}
        raise ValueError(f'Unexpected Dart expression: {t}')
    return value()

def sessions():
    result = {}
    for filename in ['revised_intro.dart', 'gdata_a.dart', 'revised_prep.dart', 'gdata_b.dart', 'gdata_c.dart']:
        source = (ROOT/'lib'/filename).read_text()
        for m in re.finditer(r'final SessionSpec session(\d+)\s*=\s*', source):
            result[int(m[1])] = parse_constructor(source, m.end())
    return result

def main():
    specs = sessions(); assert sorted(specs) == list(range(1, 9))
    expected_cards = [22, 8, 8, 10, 8, 8, 3, 8]
    totals = []; assets = set(); all_products = set()
    for no, spec in sorted(specs.items()):
        assert spec['no'] == no
        assert len(spec['terms']) == expected_cards[no-1], (no, 'card count')
        assert len(spec['rounds']) == 3
        assert spec['caps'][0]['args'][0] == 0
        times = [cap['args'][0] for cap in spec['caps']]
        assert times == sorted(times) and times[-1] < 120
        for term in spec['terms']:
            assert term['args'][0] and term['args'][1]
            if term.get('image'): assets.add(term['image'])
        counts = []
        for r in spec['rounds']:
            kind = r['args'][0]
            field = {'scramble': 'words', 'pairs': 'pairs', 'slots': 'steps', 'swap': 'steps', 'mc': 'qs', 'picture': 'qs', 'catch': 'good', 'sort': 'cards', 'vault': 'locks', 'pin': 'pins'}[kind]
            items = r[field]; counts.append(len(items))
            for item in items:
                a = item['args']
                if field == 'qs': assert 0 <= a[2] < len(a[1]), (no, a[0])
                if field == 'words': assert collections.Counter(a[0]) == collections.Counter(a[2]), (no, a)
                if field == 'cards': assert 0 <= a[2] < len(r['bins'])
        assert counts == ([8, 6, 6] if no == 2 else [6, 6, 5] if no == 5 else [6, 5, 6]), (no, counts)
        for prod in spec['products']:
            pid, _, price = prod['args'][:3]
            assert pid not in all_products and price > 0
            all_products.add(pid)
        sim = spec['sim']; tray = {i['args'][0]: i for i in sim['tray']}; zones = {z['args'][0] for z in sim['zones']}
        outputs = []
        for v in sim['variants']:
            assert v['args'][3] and v['args'][4]
            effects = collections.Counter(); used = set()
            for step in v['args'][4]:
                item, zone = step['args'][:2]
                assert item in tray and zone in zones, (no, item, zone)
                assert not tray[item].get('distractor', False)
                assert item not in used or tray[item].get('reusable', False), (no, 'reused', item)
                used.add(item)
                effects.update(step.get('fx', {}))
            for payoff in v['args'][5]: effects.update(payoff.get('fx', {}))
            outputs.append(dict(effects))
        if no == 1: assert outputs[0]['atp'] == 31
        if no == 3: assert outputs[0]['net'] == 2 and outputs[0]['nadh'] == 2 and outputs[0]['pyruvate'] == 2
        if no == 4: assert outputs[0] == {'acetyl': 2, 'co2': 2, 'nadh': 2}
        if no == 5: assert outputs[0]['atp'] == 1 and outputs[0]['co2'] == 2
        if no == 6: assert outputs[0]['atp'] in range(26, 29)
        if no >= 7:
            assert outputs[0]['net'] in range(30, 33) and outputs[0]['co2'] == 6
            assert outputs[0]['nadh'] == 0 and outputs[0]['fadh2'] == 0
            assert outputs[1]['net'] == outputs[2]['net'] == 2
            assert outputs[1]['made'] == outputs[2]['made'] == 4
            assert sim['requiredVariantGroups'] == [[0], [1, 2]]
        totals.append({'session': no, 'title': spec['hubTitle'], 'cards': len(spec['terms']), 'round_items': counts, 'max_coins': sum(counts)*50, 'simulation_outputs': outputs})
    yaml = (ROOT/'pubspec.yaml').read_text()
    for asset in assets:
        assert (ROOT/asset).is_file(), asset
        assert str(Path(asset).parent).replace('\\', '/')+'/' in yaml, asset
    assert (ROOT/'assets/revised/audio/explore_ambient.wav').is_file()
    # SDK-dependent syntax checking is optional here, but was run during preparation.
    syntax_status = 'not run: optional tree-sitter packages unavailable'
    try:
        from tree_sitter import Language, Parser
        import tree_sitter_dart
        parser = Parser(Language(tree_sitter_dart.language()))
        for path in (ROOT/'lib').glob('*.dart'):
            assert not parser.parse(path.read_bytes()).root_node.has_error, f'Dart syntax: {path}'
        syntax_status = 'passed for all lib/*.dart files'
    except ImportError: pass
    result = {'status': 'passed', 'scope': 'Static content and Dart grammar checks only; no Flutter compilation or device execution', 'dart_syntax': syntax_status, 'referenced_card_images': len(assets), 'sessions': totals}
    print(json.dumps(result, indent=2, ensure_ascii=False))
    (ROOT/'docs/static_validation.json').write_text(json.dumps(result, indent=2, ensure_ascii=False)+'\n')

if __name__ == '__main__': main()
