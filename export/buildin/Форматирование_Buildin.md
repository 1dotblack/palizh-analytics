# Правила форматирования для выгрузки в Buildin

Конвертер: `tools/md_to_buildin_blocks.rb` (локально) и `~/.cursor/skills/buildin-export/scripts/lib/` (sync). Публикация: `buildin_publish.rb` — native table через shell + append rows.

Проверка native-таблиц:

```bash
ruby tools/publish_buildin_table_test.rb
# → export/buildin/NATIVE_TABLE_TEST.json (verdict PASS/FAIL)
```

## Таблицы — native (по умолчанию в выгрузке)

GFM-таблицы (`| col |` + `|---|`) конвертируются в **native блок `table`**:

1. `md_to_content_sequence` → элемент `{ kind: "table", rows: [...] }`.
2. `buildin_publish_native_table!`: `PATCH /blocks/{page}/children` — пустой shell таблицы.
3. `PATCH /blocks/{table_id}/children` — append `table_row` с ячейками (пачками ≤100).

**Почему двухфазно:** Buildin write API **отбрасывает** nested `children` у блока `table` при одном запросе.

Обёртка `tools/sync_buildin_export.rb` задаёт `BUILDIN_TABLE_MODE=native`.

Переменная `BUILDIN_TABLE_MODE` (по умолчанию **`native`**):

| Режим | Поведение |
|-------|-----------|
| **native** | блок `table` + append `table_row` (рекомендуется) |
| **database** | inline database — запасной путь |
| **steps** | колонка `№` → h3 + буллеты |
| **markdown** | блок кода с GFM |

Запасной путь (inline database):

```bash
BUILDIN_TABLE_MODE=database ruby tools/sync_buildin_export.rb --section 02_чтз
ruby tools/publish_buildin_database_table_test.rb
```

Переопубликовать документ с таблицами: удалить `source_rel` из `PAGE_MAP.json` и снова запустить sync.

## Прочие элементы

| Markdown | Buildin |
|----------|---------|
| `#` … `###` | heading_1 … heading_3 |
| Абзац | paragraph (**bold**, *italic*, `code`, ссылки) |
| `-` списки | bulleted_list_item |
| `1.` | numbered_list_item |
| `>` | quote |
| `---` | divider |
| GFM-таблица | native **table** (`BUILDIN_TABLE_MODE=native`, по умолчанию) |
| ` ``` ` | code |

## Не поддерживается

- Mermaid (оставлять как текст или код)
- Вложенные списки
- Изображения (нужен upload API)

## Обновление уже выгруженных страниц

Удалите нужный `source_rel` из `export/buildin/PAGE_MAP.json` → `ruby tools/sync_buildin_export.rb`.

Страницы, выгруженные в режиме **database**, при переходе на native — переопубликовать (удалить из PAGE_MAP и sync заново).
