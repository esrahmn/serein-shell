"""Build assets/icons/SereinIcons*.ttf: Phosphor with a ligature for every Material Symbols name.

Usage: python3 build-icon-font.py <path to @phosphor-icons/web/src> <output dir>
(npm pack @phosphor-icons/web, then extract it). Needs fontTools and the Material Symbols Rounded font.
"""
import json, re, sys, os
PHOS, OUT = sys.argv[1], sys.argv[2]

def codepoints(style, prefix):
    css = open(f'{PHOS}/{style}/style.css').read()
    return dict(re.findall(r'\.' + prefix + r'\.ph-([a-z0-9-]+):before\s*\{\s*content:\s*"\\([0-9a-f]+)"', css))

from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables as ot
from fontTools.ttLib.tables._g_l_y_f import Glyph
from mapping import M

M.update({"music_cast":"broadcast","router":"broadcast"})

# all Material ligature names
mat = TTFont('/usr/share/fonts/TTF/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf')
c2g = mat.getBestCmap(); g2c = {v: chr(k) for k, v in c2g.items()}
names = set()
for lk in mat['GSUB'].table.LookupList.Lookup:
    for st in lk.SubTable:
        if hasattr(st, 'ExtSubTable'): st = st.ExtSubTable
        if hasattr(st, 'ligatures'):
            for first, ligs in st.ligatures.items():
                for l in ligs:
                    try: names.add(''.join(g2c[x] for x in [first] + l.Component))
                    except KeyError: pass

def generic(n):
    if n in M: return M[n]
    m = re.fullmatch(r'battery_(\d)_bar', n)
    if m: return ['battery-empty','battery-low','battery-low','battery-medium','battery-medium','battery-high','battery-high','battery-full'][int(m.group(1))]
    if re.fullmatch(r'battery_charging_\d+', n): return 'battery-charging'
    if re.fullmatch(r'battery_android_.*', n): return 'battery-medium'
    m = re.fullmatch(r'(signal|network)_wifi_(\d)_bar(_locked)?', n)
    if m: return ['wifi-none','wifi-low','wifi-medium','wifi-high','wifi-high'][int(m.group(2))]
    m = re.fullmatch(r'(signal|network)_wifi(_locked)?', n)
    if m: return 'wifi-high'
    if n.endswith('_locked'): return 'lock'
    return 'question'

def build(src, out, family, cps):
    f = TTFont(src)
    cmap = f.getBestCmap()
    order = f.getGlyphOrder()
    glyf, hmtx = f['glyf'], f['hmtx']
    # glyphs for characters Phosphor's own ligatures never needed
    extra = {'_': 'underscore', **{str(i): n for i, n in enumerate(['zero','one','two','three','four','five','six','seven','eight','nine'])}}
    for ch, gn in extra.items():
        if ord(ch) in cmap: continue
        order.append(gn); glyf.glyphs[gn] = Glyph(); hmtx.metrics[gn] = (0, 0)
        for t in f['cmap'].tables:
            if t.isUnicode(): t.cmap[ord(ch)] = gn
    f.setGlyphOrder(order); glyf.glyphOrder = order
    f['maxp'].numGlyphs = len(order)
    cmap = f.getBestCmap()
    # ligatures: Material name -> Phosphor glyph
    ligs = {}
    miss = set()
    for n in sorted(names | set(M)):
        target = generic(n)
        if target not in cps: miss.add((n, target)); target = 'question'
        tg = cmap[int(cps[target], 16)]
        seq = [cmap[ord(c)] for c in n]
        l = ot.Ligature(); l.Component = seq[1:]; l.LigGlyph = tg
        ligs.setdefault(seq[0], []).append(l)
    for k in ligs: ligs[k].sort(key=lambda l: -len(l.Component))
    st = ot.LigatureSubst(); st.ligatures = ligs
    lk = ot.Lookup(); lk.LookupType = 4; lk.LookupFlag = 0; lk.SubTable = [st]; lk.SubTableCount = 1
    gsub = f['GSUB'].table
    gsub.LookupList.Lookup.insert(0, lk)
    gsub.LookupList.LookupCount = len(gsub.LookupList.Lookup)
    # shift existing indices, then put ours first in every liga/calt feature
    for fr in gsub.FeatureList.FeatureRecord:
        feat = fr.Feature
        feat.LookupListIndex = [i + 1 for i in feat.LookupListIndex]
        if fr.FeatureTag in ('liga', 'calt', 'clig'):
            feat.LookupListIndex.insert(0, 0)
        feat.LookupCount = len(feat.LookupListIndex)
    # Phosphor's glyph headers carry stale bounds (xMin 0); after fontTools recalculates them the
    # left side bearings must match, or renderers shift every glyph left by its real xMin.
    for gn in order:
        g = glyf[gn]
        g.recalcBounds(glyf)
        hmtx.metrics[gn] = (hmtx.metrics[gn][0], getattr(g, 'xMin', 0) if g.numberOfContours else 0)
    for rec in f['name'].names:
        if rec.nameID in (1, 4, 16): rec.string = family
        elif rec.nameID == 6: rec.string = family.replace(' ', '')
        elif rec.nameID in (2, 17): rec.string = 'Regular'
    f.save(out)
    return miss

os.makedirs(OUT, exist_ok=True)
miss = build(f'{PHOS}/regular/Phosphor.ttf', f'{OUT}/SereinIcons.ttf', 'SereinIcons', codepoints('regular', 'ph'))
build(f'{PHOS}/bold/Phosphor-Bold.ttf', f'{OUT}/SereinIcons-Bold.ttf', 'SereinIcons Bold', codepoints('bold', 'ph-bold'))
build(f'{PHOS}/fill/Phosphor-Fill.ttf', f'{OUT}/SereinIcons-Fill.ttf', 'SereinIcons Fill', codepoints('fill', 'ph-fill'))
print('missing targets:', miss)
print('ligatures for', len(names | set(M)), 'names')
