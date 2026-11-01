"""Attach more files to an already published GitHub release of this repo (e.g. the guide PDFs).

Usage (Windows, from the repo): python -I tools/gh_release_asset.py <tag> <file> [<file> ...]
The token comes from the stored HTTPS credential (`git credential fill`) and is never printed or saved.
An asset with the same name is replaced.
"""
import json, os, subprocess, sys, urllib.request, urllib.error, urllib.parse

REPO = "kostyamat/BitPerfec-Audio-Qf-module-Magisk"
TAG, FILES = sys.argv[1], sys.argv[2:]

env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
out = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
                     capture_output=True, text=True, env=env, timeout=30).stdout
tok = dict(l.split("=", 1) for l in out.splitlines() if "=" in l).get("password")
if not tok:
    sys.exit("no stored GitHub credential")


def call(method, url, data=None, ctype="application/json"):
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "token " + tok, "Accept": "application/vnd.github+json", "Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"{}")


st, rel = call("GET", f"https://api.github.com/repos/{REPO}/releases/tags/{TAG}")
if st != 200:
    sys.exit(f"no release {TAG}: {st}")
for f in FILES:
    name = os.path.basename(f)
    for a in rel.get("assets", []):
        if a["name"] == name:
            call("DELETE", f"https://api.github.com/repos/{REPO}/releases/assets/{a['id']}")
    ctype = "application/pdf" if name.endswith(".pdf") else "application/octet-stream"
    up = rel["upload_url"].split("{")[0] + "?name=" + urllib.parse.quote(name)
    st, a = call("POST", up, open(f, "rb").read(), ctype)
    print("asset:", st, a.get("browser_download_url", a.get("message")), a.get("size"))
