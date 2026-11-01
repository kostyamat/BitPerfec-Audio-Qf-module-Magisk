"""Build the user guide PDFs (docs/GUIDE.<lang>.md -> BitPerfect_Guide_<ver>_<lang>.pdf) for a release.

Usage (Windows, from the repo): python -I tools/build_guide_pdf.py <version> <out dir>
Markdown -> HTML (python-markdown, tables) with A4 print styles; the screenshots load from docs/img/; links between
the guides point to GitHub. Printed by Microsoft Edge headless, which renders Cyrillic and the PNGs as they are.
The PDFs are release assets, not repository files.
"""
import os, re, subprocess, sys, tempfile
import markdown

VER, OUT = sys.argv[1], os.path.abspath(sys.argv[2])
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")
GH = "https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/"
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

CSS = """
@page { size: A4; margin: 16mm 15mm; }
body { font-family: 'Segoe UI', Roboto, 'DejaVu Sans', sans-serif; font-size: 10.5pt; line-height: 1.45; color: #1b1f24; }
h1 { font-size: 22pt; color: #0b7285; border-bottom: 3px solid #00b4d8; padding-bottom: 4px; margin-top: 0; }
h2 { font-size: 15pt; color: #0b7285; margin-top: 18pt; border-bottom: 1px solid #d0d7de; padding-bottom: 2px;
     page-break-after: avoid; }
h3 { font-size: 12pt; page-break-after: avoid; }
p, li { orphans: 3; widows: 3; }
img { display: block; max-width: 100%; margin: 6pt auto 10pt; border: 1px solid #d0d7de; border-radius: 6px;
      page-break-inside: avoid; }
table { border-collapse: collapse; width: 100%; margin: 6pt 0 10pt; page-break-inside: avoid; font-size: 9.5pt; }
th, td { border: 1px solid #d0d7de; padding: 4px 6px; vertical-align: top; text-align: left; }
th { background: #eef6f8; }
code { font-family: Consolas, 'DejaVu Sans Mono', monospace; font-size: 9pt; background: #f2f4f6; padding: 0 3px;
       border-radius: 3px; }
hr { border: 0; border-top: 1px solid #d0d7de; margin: 12pt 0; }
a { color: #0b7285; text-decoration: none; }
.cover { color: #57606a; font-size: 9pt; margin-bottom: 10pt; }
"""

os.makedirs(OUT, exist_ok=True)
for lang in ("en", "uk"):
    src = open(os.path.join(DOCS, f"GUIDE.{lang}.md"), encoding="utf-8").read()
    # the other guide is a separate file: point at GitHub instead of a local path
    src = re.sub(r"\]\((GUIDE\.(en|uk)\.md)\)", lambda m: f"]({GH}{m.group(1)})", src)
    body = markdown.markdown(src, extensions=["tables", "sane_lists"])
    base = "file:///" + DOCS.replace("\\", "/") + "/"
    html = (f"<!doctype html><html lang='{lang}'><head><meta charset='utf-8'><base href='{base}'>"
            f"<title>BitPerfect {VER}</title><style>{CSS}</style></head><body>"
            f"<div class='cover'>BitPerfect {VER} · github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk</div>"
            f"{body}</body></html>")
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(html)
        tmp = f.name
    pdf = os.path.join(OUT, f"BitPerfect_Guide_{VER}_{lang}.pdf")
    subprocess.run([EDGE, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                    "--allow-file-access-from-files", f"--print-to-pdf={pdf}", "file:///" + tmp.replace("\\", "/")],
                   check=True, timeout=120, capture_output=True)
    os.unlink(tmp)
    print(pdf, os.path.getsize(pdf))
