#!/usr/bin/env bash
# Полная синхронизация: пересборка bundle → удаление всех источников блокнота → загрузка файлов заново.
# Требует: notebooklm-py в PATH (`notebooklm login`), python3 для разбора JSON.
#
# Из корня репозитория: ./tools/sync_notebooklm.sh
# Альтернативная команда Claude/Cursor при запросе «обнови блокнот NotebookLM»: bash tools/sync_notebooklm.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_FILE="$REPO_ROOT/export/notebooklm/NOTEBOOK_TARGET"
NOTEBOOKLM_BIN="${NOTEBOOKLM:-notebooklm}"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "Ошибка: нет файла $TARGET_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$TARGET_FILE"

if [[ -z "${NOTEBOOK_ID:-}" ]]; then
  echo "Ошибка: в NOTEBOOK_TARGET задайте NOTEBOOK_ID" >&2
  exit 1
fi

if ! command -v "$NOTEBOOKLM_BIN" >/dev/null 2>&1; then
  echo "Ошибка: команда «$NOTEBOOKLM_BIN» не найдена. Добавьте venv NotebookLM в PATH или задайте NOTEBOOKLM=/путь/bin/notebooklm" >&2
  exit 1
fi

cd "$REPO_ROOT"
ruby tools/build_notebooklm_bundle.rb

BUNDLE="$REPO_ROOT/export/notebooklm/bundle"
IDS=$("$NOTEBOOKLM_BIN" source list --json -n "$NOTEBOOK_ID" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for s in data.get('sources') or []:
    i = s.get('id')
    if i:
        print(i)
")

while IFS= read -r sid; do
  [[ -z "$sid" ]] && continue
  "$NOTEBOOKLM_BIN" source delete "$sid" -n "$NOTEBOOK_ID" -y
done <<< "$IDS"

shopt -s nullglob
for f in "$BUNDLE"/*.md; do
  "$NOTEBOOKLM_BIN" source add "$f" -n "$NOTEBOOK_ID"
done
shopt -u nullglob

echo '(В блокнот только bundle/*.md, включая 09–12 .md с OpenAPI в fenced yaml; одноимённые .yaml не загружаются.)' >&2

echo "Готово. Блокнот: ${NOTEBOOK_TITLE:-} ($NOTEBOOK_ID)"
echo "Индексация может занять время; проверка: $NOTEBOOKLM_BIN source list --json -n \"$NOTEBOOK_ID\""
