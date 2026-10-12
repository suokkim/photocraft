#!/usr/bin/env bash
# 원본 아이콘 → PhotoCraft ok 아이콘 (정식 판과 한눈에 구분되게, 디렉터 10-12)
#   배경색을 파랑 → 주황으로 돌리고(hue), 오른쪽 아래에 흰 "ok" 표.
#   ok/icon.sh <원본.icns> <결과.icns>
set -euo pipefail
SRC="$1" OUT="$2"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
iconutil -c iconset -o "$TMP/in.iconset" "$SRC"
mkdir "$TMP/out.iconset"
for f in "$TMP/in.iconset"/*.png; do
  ffmpeg -v error -y -i "$f" -vf "format=rgba,hue=h=150:s=1.3" "$TMP/out.iconset/$(basename "$f")"
done
python3 - "$TMP/out.iconset" <<'PY'
import sys, glob
from PIL import Image, ImageDraw, ImageFont
for p in glob.glob(sys.argv[1] + "/*.png"):
    im = Image.open(p).convert("RGBA"); s = im.width
    if s < 64:            # 아주 작은 아이콘은 색만 — 글자가 뭉개진다
        continue
    d = ImageDraw.Draw(im)
    w, h = int(s * .40), int(s * .24)
    x1, y1 = int(s * .88), int(s * .88)
    d.rounded_rectangle((x1 - w, y1 - h, x1, y1), radius=h // 2, fill="white")
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(h * .78))
    d.text((x1 - w / 2, y1 - h / 2), "ok", font=font, fill="#1a1a1a", anchor="mm")
    im.save(p)
PY
iconutil -c icns -o "$OUT" "$TMP/out.iconset"
