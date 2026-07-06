# Сценарий выгрузки в Buildin (для агента)

Пошаговый чек-лист при запросе «выгрузи / обнови документацию в Buildin».

## 0. Предусловия

- [ ] MCP **Buildin** авторизован в Cursor
- [ ] В [BUILDIN_TARGET](BUILDIN_TARGET) актуальный `PAGE_ID`
- [ ] Бот/интеграция Buildin имеет доступ к целевой странице (`API-getPage` без 403)

## 1. Сборка локального bundle

```bash
ruby tools/build_buildin_bundle.rb
```

Прочитать `export/buildin/manifest.json`.

## 2. Проверка целевой страницы

`API-getPage` с `page_id` из BUILDIN_TARGET.

При 403 — остановиться, попросить пользователя выдать доступ боту на страницу и дочерние.

## 3. Создание разделов (один раз или при полной выгрузке)

Для каждого узла верхнего уровня в `manifest.tree.children`:

1. Проверить `export/buildin/PAGE_MAP.json` → `sections[section]`
2. Если нет — `API-createPage`:
   - `parent`: `{ "page_id": "<PAGE_ID из BUILDIN_TARGET>" }`
   - `icon`: emoji из manifest
   - `properties.title`: название раздела
   - `children`: callout с датой синхронизации и ссылкой на репозиторий
3. Записать `page_id` раздела в PAGE_MAP

## 4. Выгрузка документов

Для каждого документа в разделе (`kind`: `document` | `openapi`):

1. Прочитать `bundle/<bundle_path>`
2. Конвертировать: `ruby tools/md_to_buildin_blocks.rb "bundle/..." --out /tmp/b.json`
3. Если в PAGE_MAP `documents[source_rel]` есть `page_id` и режим **обновление**:
   - Очистить содержимое: получить `API-getBlockChildren`, удалить старые блоки через `API-updateBlock` (archived) **или** создать новую страницу и обновить PAGE_MAP (проще при полной пересборке)
   - **Рекомендация для MVP:** при полной выгрузке создавать новые страницы; старые помечать в отчёте для ручной архивации
4. Иначе `API-createPage`:
   - `parent`: `{ "page_id": "<section_page_id>" }`
   - `properties.title`: `title` из manifest
   - `children`: первая пачка блоков (до 100)
5. Остальные пачки — `API-appendBlockChildren` на `page_id` документа
6. Сохранить в PAGE_MAP: `page_id`, `url`, `synced_at`, `git_rev`

## 5. Оформление страницы документа

В начало содержимого (первые блоки `children`):

1. **Callout** (ℹ️): «Источник: `path/in/repo.md` · синхронизировано ГГГГ-ММ-ДД»
2. **Divider**
3. Далее — тело из конвертера

Заголовок H1 в MD не дублировать в теле, если он совпадает с `properties.title`.

## 6. Завершение

- Обновить `PAGE_MAP.json`: `last_sync`, `git_rev`
- Обновить `MANIFEST.md` (пересборка bundle)
- Краткий отчёт пользователю: число разделов/страниц, ссылка на корневую страницу, ошибки 429 (пауза и retry)

## Лимиты API

- Не более **100 блоков** за один `createPage` / `appendBlockChildren`
- Текст в `rich_text` — до **2000** символов (конвертер режет автоматически)
- При **429** — пауза 2–5 с, повтор до 3 раз
- `Idempotency-Key` на `createPage` при повторных попытках: `palizh-<source_rel hash>-<date>`

## Частичная выгрузка

| Запрос | Действие |
|--------|----------|
| «только ЧТЗ» | Только `section: "02_чтз"` |
| «обнови 03_доставка» | Один `source_rel` |
| «полная выгрузка» | Все разделы manifest |
