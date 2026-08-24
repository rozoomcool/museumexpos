#!/usr/bin/env bash
# Копирует model-viewer из пакета flutter_3d_controller в web/.
#
# На вебе пакет вырезает из своего шаблона тег подключения библиотеки и ждёт,
# что <model-viewer> уже зарегистрирован страницей. Берём ту же самую сборку из
# pub-cache, а не с CDN, чтобы веб-версия работала без сети — как и остальные.
# Запускать после обновления flutter_3d_controller.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC=$(ls -d "$HOME"/.pub-cache/hosted/pub.dev/flutter_3d_controller-*/assets/model_viewer.min.js | tail -1)
cp "$SRC" "$ROOT/web/model-viewer.min.js"
echo "скопировано: $SRC -> web/model-viewer.min.js"
