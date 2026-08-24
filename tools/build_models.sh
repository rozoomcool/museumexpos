#!/usr/bin/env bash
# Конвертирует исходные .glb (по 50-107 МБ) в облегчённые модели для приложения.
# Draco не используется: model-viewer подгружает его декодер с CDN, а приложение
# должно работать офлайн. Квантование (KHR_mesh_quantization) и WebP-текстуры
# декодируются штатно, без внешних файлов.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GT="$ROOT/tools/node_modules/.bin/gltf-transform"
JOBS="$ROOT/tools/model_jobs.json"

total=$(python3 -c "import json;print(len(json.load(open('$JOBS'))))")
i=0
fail=0

while IFS=$'\t' read -r src dst; do
  i=$((i + 1))
  printf '[%2d/%2d] %s\n' "$i" "$total" "$(basename "$dst")"
  if ! "$GT" optimize "$src" "$dst" \
      --compress quantize \
      --texture-compress webp \
      --texture-size 2048 \
      --simplify true \
      --simplify-error 0.0001 > /dev/null 2>"$ROOT/tools/.last_error"; then
    echo "  ОШИБКА:"; sed 's/^/    /' "$ROOT/tools/.last_error" | tail -5
    fail=$((fail + 1))
  fi
done < <(python3 -c "
import json
for j in json.load(open('$JOBS')):
    print(j['src'], j['dst'], sep='\t')
")

rm -f "$ROOT/tools/.last_error"
echo
echo "готово: $((i - fail))/$total моделей, ошибок: $fail"
du -sh "$ROOT/assets/models"
