# Правила форматирования для выгрузки в Buildin

Конвертер: `tools/md_to_buildin_blocks.rb`. API-хелперы: `tools/buildin_api.rb`.

Проверка таблиц и markdown API:

```bash
ruby tools/publish_buildin_markdown_test.rb
ruby tools/publish_buildin_style_test.rb
```

## Таблицы — database (по умолчанию в выгрузке)

GFM-таблицы (`| col |` + `|---|`) конвертируются в **inline database** (`tools/md_table_database.rb`):

1. `md_to_content_sequence` разбивает MD на блоки и элементы `{ kind: database }`.
2. `POST /v2/databases` (`is_inline: true`) — колонки по заголовкам таблицы.
3. `POST /v2/pages` с `parent.database_id` — строки с inline-разметкой в ячейках.

Переменная `BUILDIN_TABLE_MODE` (по умолчанию **`database`**):

| Режим | Поведение |
|-------|-----------|
| **database** | inline database (рекомендуется) |
| **native** | блоки `table` / `table_row` (ячейки через API пустые) |
| **steps** | колонка `№` → h3 + буллеты |
| **markdown** | блок кода с GFM |

Тесты:

```bash
ruby tools/publish_buildin_database_table_test.rb
ruby tools/publish_buildin_style_test.rb
ruby tools/sync_buildin_export.rb   # новые документы — с database
```

Переопубликовать документ с таблицами: удалить `source_rel` из `PAGE_MAP.json` и снова запустить sync.

## Таблицы — native blocks (ограничение API)

Нативные `table` / `table_row` через blocks API **не сохраняют текст ячеек** (баг write API). Импорт MD в UI работает — см. [Аудит](https://buildin.ai/fbbd0ef4-99dc-4445-9db0-32b6a1c99475).

## Прочие элементы

| Markdown | Buildin |
|----------|---------|
| `#` … `###` | heading_1 … heading_3 |
| Абзац | paragraph (**bold**, *italic*, `code`, ссылки) |
| `-` списки | bulleted_list_item |
| `1.` | numbered_list_item |
| `>` | quote |
| `---` | divider |
| GFM-таблица | inline **database** (`BUILDIN_TABLE_MODE=database`, по умолчанию) |
| ` ``` ` | code |

## Не поддерживается

- Mermaid (оставлять как текст или код)
- Вложенные списки
- Изображения (нужен upload API)

## Обновление уже выгруженных страниц

Удалите нужный `source_rel` из `export/buildin/PAGE_MAP.json` → `ruby tools/sync_buildin_export.rb`.

Для страниц с таблицами надёжнее: удалить запись из PAGE_MAP и **переимпортировать MD в UI**, пока нет PUT markdown.
