# Выгрузка документации Palizh в Buildin

> **Политика (2026-06-29):** публикация в Buildin (`sync_buildin_export.rb`) — **только по явному запросу**, не автоматически при аудите документации.

Иерархическая публикация ключевых артефактов проекта на **страницу Cursor** в Buildin (глобальный навык `@buildin-export`, агент `@agent-buildin-export`).

## Целевая страница

| Параметр | Значение |
|----------|----------|
| URL | https://buildin.ai/dd988cac-7a50-4f87-8d96-23a166f9d54b |
| ID | `dd988cac-7a50-4f87-8d96-23a166f9d54b` |
| Конфиг | [BUILDIN_TARGET](BUILDIN_TARGET) |

Перед первой выгрузкой **выдайте интеграции / боту Buildin доступ** к этой странице (и к дочерним). Без прав API вернёт `403 forbidden`.

## Быстрый старт

1. Убедиться, что MCP **Buildin** подключён и авторизован в Cursor.
2. Выдать боту права на целевую страницу в Buildin.
3. **Полная выгрузка** (по умолчанию очищает страницу Cursor и публикует заново):

```bash
ruby tools/sync_buildin_export.rb
```

Только новые документы без очистки:

```bash
ruby tools/sync_buildin_export.rb --incremental
```

Скрипт делегирует в `~/.cursor/skills/buildin-export/scripts/sync_buildin_export.rb`.

4. Или в чате: **`@buildin-export`** / **`@agent-buildin-export выгрузи документацию`**.

## Состав выгрузки

Редактируйте **`export/buildin/SOURCES.json`** — разделы, явные файлы (`items`), маски (`include`), исключения, OpenAPI (`yaml_as_markdown`). Поле `agreement` — текст согласования.

После правок:

```bash
ruby tools/build_buildin_bundle.rb   # → manifest.json, SOURCES.md, MANIFEST.md
ruby tools/sync_buildin_export.rb
```

Схема полей: `~/.cursor/skills/buildin-export/reference.md`

## Пересборка bundle (без выгрузки)

```bash
ruby tools/build_buildin_bundle.rb
```

Результат:

- `bundle/` — дерево Markdown по разделам
- `manifest.json` — машиночитаемое дерево для агента
- `MANIFEST.md` — человекочитаемый список

## Конвертация Markdown → блоки Buildin

```bash
ruby tools/md_to_buildin_blocks.rb export/buildin/bundle/02_чтз/01_процесс_оформления_заказа.md --out /tmp/blocks.json
```

Скрипт режет блоки пачками (по умолчанию 100) для `API-appendBlockChildren`.

## Режимы выгрузки

| Режим | Запрос / флаг | Поведение |
|-------|----------------|-----------|
| **Полная (replace)** | по умолчанию, «выгрузи всё» | Очистка PAGE_MAP + блоков корня, затем весь manifest |
| **Инкремент** | `--incremental` | Только документы, которых нет в PAGE_MAP |
| **Раздел** | `--section 02_чтз` | Один блок `section` из manifest |
| **Dry-run** | `--dry-run` | План без API |

## Отличие от NotebookLM

| | NotebookLM | Buildin |
|---|------------|---------|
| Формат | ~15 крупных merged-файлов | Иерархия страниц по разделам |
| Инструмент | CLI `notebooklm` | MCP Buildin |
| Обновление | `./tools/sync_notebooklm.sh` | Агент `@agent-buildin-export` |

Состав источников согласован с [export/notebooklm/SOURCES.md](../notebooklm/SOURCES.md), но **без слияния** — каждый исходный `.md` остаётся отдельной страницей.

## Файлы каталога

- `BUILDIN_TARGET` — ID и URL целевой страницы
- `SOURCES.md` — описание дерева разделов
- `PAGE_MAP.json` — карта выгруженных страниц (заполняет агент)
- `Сценарий_выгрузки_Buildin.md` — пошаговый сценарий для агента
