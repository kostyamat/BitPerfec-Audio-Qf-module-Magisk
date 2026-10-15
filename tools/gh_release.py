"""Publish a GitHub release of this repo with the module zip attached.

Usage (Windows, from the repo): python -I tools/gh_release.py <tag> <full commit sha> <body.md> <zip>
The token comes from the stored HTTPS credential (`git credential fill`) and is never printed or saved.
`target_commitish` must be a FULL sha or a branch name - a short sha is rejected (422).
Pushing the branch stays in WSL (SSH keys live there); the GitHub API works from Windows.
"""
import json, os, subprocess, sys, urllib.request, urllib.error

REPO = "kostyamat/BitPerfec-Audio-Qf-module-Magisk"
TAG, TARGET = sys.argv[1], sys.argv[2]
BODY = open(sys.argv[3], encoding="utf-8").read()
ASSET = sys.argv[4]
NAME = f"BitPerfect {TAG}"

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
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"{}")

st, rel = call("GET", f"https://api.github.com/repos/{REPO}/releases/tags/{TAG}")
if st == 200:
    sys.exit(f"release {TAG} already exists: {rel.get('html_url')}")
st, rel = call("POST", f"https://api.github.com/repos/{REPO}/releases",
               json.dumps({"tag_name": TAG, "target_commitish": TARGET, "name": NAME, "body": BODY,
                           "draft": False, "prerelease": False}).encode())
if st != 201:
    sys.exit(f"create failed {st}: {rel.get('message')} {rel.get('errors')}")
print("release:", rel["html_url"])
up = rel["upload_url"].split("{")[0] + "?name=" + os.path.basename(ASSET)
st, a = call("POST", up, open(ASSET, "rb").read(), "application/zip")
print("asset:", st, a.get("browser_download_url"), a.get("size"))
