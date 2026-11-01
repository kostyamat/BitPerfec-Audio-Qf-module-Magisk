"""Build profiles/sp9863a/ from the UIS8581 factory files: BitPerfect's 7862 edits, ported only where the
8581 base is identical to the 7862 factory base. Run from the repo root:

    python -I tools/build_8581_profile.py "D:/Release/update(2)" D:/Release/8581_QF005

Prints every edit it ports and every one it refuses. The installer applies the built files as they are.
"""
import os
import sys
import xml.etree.ElementTree as ET

F7 = os.path.join(sys.argv[1], "vendor/vendor/etc")
F8 = os.path.join(sys.argv[2], "vendor/vendor/etc")
OURS = "common/system/vendor/etc"
OUT = "profiles/sp9863a/system/vendor/etc"
os.makedirs(OUT, exist_ok=True)


def load(p):
    return ET.parse(p)


def points(v):
    return [p.text.strip() for p in v.findall("point")]


def curves(root):
    """(group-or-stream, deviceCategory, or curve name) -> element"""
    out = {}
    for v in root.iter("volume"):
        key = (v.get("stream") or "", v.get("deviceCategory") or "", v.get("name") or "")
        out[key] = v
    # named curves: <reference name="DEFAULT_MEDIA_VOLUME_CURVE"><point>...</reference>
    for r in root.iter("reference"):
        out[("ref:" + (r.get("name") or ""), "", "")] = r
    # engine file: volumeGroup/name + volume deviceCategory
    for g in root.iter("volumeGroup"):
        name = g.findtext("name")
        for v in g.findall("volume"):
            out[("group:" + (name or ""), v.get("deviceCategory") or "", "")] = v
    return out


def port_curves(fname, skip=()):
    """Returns (tree, refused group/stream names)."""
    refused = set()
    t7, to, t8 = load(f"{F7}/{fname}"), load(f"{OURS}/{fname}"), load(f"{F8}/{fname}")
    c7, co, c8 = curves(t7.getroot()), curves(to.getroot()), curves(t8.getroot())
    for key, vo in co.items():
        v7 = c7.get(key)
        if v7 is None:
            continue
        same = points(v7) == points(vo) and v7.get("ref") == vo.get("ref")
        if same:
            continue
        name = key[0].replace("group:", "").replace("AUDIO_STREAM_", "").lower()
        v8 = c8.get(key)
        if name in skip:
            print(f"  REFUSED {fname} {key}: refused in the engine file, kept factory in both")
            continue
        if v8 is None:
            print(f"  REFUSED {fname} {key}: not in 8581")
            refused.add(name)
            continue
        if points(v8) != points(v7) or v8.get("ref") != v7.get("ref"):
            print(f"  REFUSED {fname} {key}: 8581 base differs from 7862")
            refused.add(name)
            continue
        for p in list(v8):
            v8.remove(p)
        v8.attrib.pop("ref", None)
        if vo.get("ref"):
            v8.set("ref", vo.get("ref"))
        for p in vo.findall("point"):
            e = ET.SubElement(v8, "point")
            e.text = p.text
        print(f"  ported  {fname} {key}: {points(vo)}")
    return t8, refused


def port_strategies(fname):
    t8 = load(f"{F8}/{fname}")
    moved = 0
    for ps in t8.getroot().iter("ProductStrategy"):
        if ps.get("name") != "STRATEGY_MEDIA":
            continue
        groups = {g.get("streamType"): g for g in ps.findall("AttributesGroup")}
        music, system = groups.get("AUDIO_STREAM_MUSIC"), groups.get("AUDIO_STREAM_SYSTEM")
        if music is None or system is None:
            sys.exit("STRATEGY_MEDIA without MUSIC/SYSTEM groups - refusing")
        for usage in ("AUDIO_USAGE_ASSISTANCE_NAVIGATION_GUIDANCE", "AUDIO_USAGE_ASSISTANT"):
            for a in music.findall("Attributes"):
                u = a.find("Usage")
                if u is not None and u.get("value") == usage:
                    music.remove(a)
                    system.append(a)
                    moved += 1
                    print(f"  ported  {fname}: {usage} MUSIC -> SYSTEM")
    if moved != 2:
        sys.exit(f"{fname}: expected to move 2 usages, moved {moved}")
    return t8


# A curve lives in two files (engine and legacy); port it only where BOTH allow it, so they never disagree.
eng, eng_refused = port_curves("audio_policy_engine_stream_volumes.xml")
leg, leg_refused = port_curves("audio_policy_volumes.xml", skip=eng_refused)
if leg_refused - eng_refused:
    sys.exit(f"legacy refused {leg_refused - eng_refused} that the engine ported - fix by hand")
built = {
    "audio_policy_engine_product_strategies.xml": port_strategies("audio_policy_engine_product_strategies.xml"),
    "audio_policy_engine_stream_volumes.xml": eng,
    "audio_policy_volumes.xml": leg,
}
for name, tree in built.items():
    tree.write(f"{OUT}/{name}", encoding="utf-8", xml_declaration=True)
print("written:", ", ".join(built))
