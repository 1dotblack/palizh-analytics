<!-- buildin-source: Техническая часть/OpenAPI_индекс.md -->

# OpenAPI Palizh: какие файлы для чего

Контракты **разделены по назначению** (клиент ↔ бэкенд и server-to-server с 1С). Монолитный `openapi_mvp.yaml` **снят**; копия последнего объединённого варианта — в `архив/openapi_mvp_monolith_2026-04-17.yaml`.

## Канон источников (GitLab разработки)

В репозитории **[gitlab.com/nutnet/palizh](https://gitlab.com/nutnet/palizh)** каталог **`docs/`** — первоисточник по соответствующим артефактам.

**Последняя подтяжка в аналитику:** `gitlab/main` **`3eb790d`** (2026-08-07) — `public-http-openapi.yaml`, `1c-http-openapi.yaml`, `incoming-hooks.md`. Аудит готовности: [`Аудит_готовности_2026-08-07.md`](../Аудит/Аудит_готовности_2026-08-07.md). Предыдущая: **`8375c0d`** (2026-07-31); **`9c3726c`** (2026-07-27); **`0802839`** (2026-07-17).

**Предыдущая подтяжка:** `b86d571` — `discountedAmount`, `shop_working_hours`, скидки в `sync.counterparties`. Ранее: `4f17e9b`, корзина/заказы (`f2824d9`).

После `git fetch gitlab` копии в этом репозитории аналитики должны совпадать с:

- `docs/public-http-openapi.yaml` ↔ `Техническая часть/public-http-openapi.yaml`
- `docs/1c-http-openapi.yaml` ↔ `Техническая часть/1c-http-openapi.yaml` и **`входящие/1c-http-openapi.yaml`** (идентичные файлы)
- `docs/incoming-hooks.md` ↔ **`входящие/incoming-hooks.md`**

Правки этих четырёх путей в аналитике выполняются **переносом из GitLab** (или явным решением изменить канон в GitLab и затем синхронизировать сюда).

**Замечание по снимку коду:** описание в `public-http-openapi.yaml` может **опережать** регистрацию маршрутов в `backend/app/Modules/Api/` (там возможна заготовка). Имеет смысл периодически сверять спеку с фактическими `Route::` контроллерами и с фронтом на стенде.

| Файл | Назначение | Кто потребляет |
| ---- | ---------- | -------------- |
| [`openapi_client_mvp.yaml`](openapi_client_mvp.yaml) | **Продуктовый черновик** витрины и ЛК (Bearer/JWT, `/catalogs/{code}/…`). **Для MVP и стенда не канон** — ориентир **`public-http-openapi.yaml`**. Файл сохранён для post-MVP и продуктовых обсуждений; см. § «Расхождение» ниже. | Продукт (целевая модель), **не** текущая разработка фронта |
| [`openapi_1c_inbound_mvp.yaml`](openapi_1c_inbound_mvp.yaml) | Формальное OpenAPI для **`POST /exchange`** (HMAC, `event` + typed `payload` по событиям каталога). Согласовать с GitLab‑модулем `Exchange` и с **`входящие/incoming-hooks.md`**. | Разработка 1С, контрактные тесты inbound |
| [`1c-http-openapi.yaml`](1c-http-openapi.yaml) | **Исходящие вызовы платформа → HTTP-сервисы 1С** (`POST /post_orders`, `GET /get_documents` и т.д.). **Basic** и сеть — на стороне заказчика; дубликат для удобства — см. также [`входящие/1c-http-openapi.yaml`](../входящие/1c-http-openapi.yaml). **Канон текста файла:** `gitlab/.../docs/1c-http-openapi.yaml`. | Бэкенд платформы, разработка 1С (публикации) |
| [`public-http-openapi.yaml`](public-http-openapi.yaml) | **Контракт публичного HTTP API** для стенда/реализации (часто SPA + Laravel Sanctum: cookie, CSRF, см. описание операций и `servers.url`). **Канон текста файла:** `gitlab/.../docs/public-http-openapi.yaml`. | Фронт, контрактные тесты стенда, сверка с продуктовым [`openapi_client_mvp.yaml`](openapi_client_mvp.yaml) |
| [`openapi_mvp_merged.yaml`](openapi_mvp_merged.yaml) | **Объединение** клиент + 1С inbound (генерация скриптом). Для Redoc/Swagger UI, линтеров, которым удобен **один** YAML. **Не править вручную.** | Демо, CI, просмотр «всё в одном» |
| [`openapi_mvp_post_mvp.yaml`](openapi_mvp_post_mvp.yaml) | Post-MVP расширения (претензии, админка, обучение и т.д.). | Планирование |

**События `POST /exchange` (расшифровка payload):** [`входящие/incoming-hooks.md`](../входящие/incoming-hooks.md) — **канон текста:** `gitlab/.../docs/incoming-hooks.md`. **Модель каталога (канон GitLab / стенд, 2026-06-02):** [`Модель_данных_каталог_1С_обмен.md`](Модель_данных_каталог_1С_обмен.md) — `sync.product-attributes`, `sync.product-types`, `sync.product-type-characteristics`, `sync.products`, `sync.stocks`, `sync.prices`, `sync.categories`, `sync.counterparties`. Формальное OpenAPI — [`openapi_1c_inbound_mvp.yaml`](openapi_1c_inbound_mvp.yaml) (**v0.4.0**): typed-схемы `payload` по событиям каталога (discriminator `event`); заказы/документы — по мере готовности 1С (#18).

**Скрипты** (каталог `Техническая часть/tools/`):

- `merge_openapi_mvp.rb` — пересобирает `openapi_mvp_merged.yaml` из `openapi_client_mvp.yaml` + `openapi_1c_inbound_mvp.yaml` (запускать после правок двух исходников).
- `split_openapi_client_and_1c.rb` — одноразовая нарезка; источник по умолчанию — архивный монолит, если снова понадобится регенерировать куски из старой одной спеки.

Скрипт **не** включает `public-http-openapi.yaml` и `1c-http-openapi.yaml` — они синхронизируются **только с GitLab `docs/`**.

### Расхождение `openapi_client_mvp.yaml` ↔ `public-http-openapi.yaml` (сверка 2026-06-26)

**Решение (2026-06-26):** для MVP **канон только `public-http-openapi.yaml`**. `openapi_client_mvp.yaml` — **устаревший для стенда** продуктовый черновик; не править под каждую подтяжку GitLab без отдельного решения.

Маршруты ниже есть в каноне стенда **`public-http-openapi.yaml`** (GitLab `docs/`), в **`openapi_client_mvp.yaml`** **не описаны** или **другая модель**:

| Метод и путь | В `public-http-openapi.yaml` | В `openapi_client_mvp.yaml` |
|--------------|------------------------------|----------------------------|
| `GET /banners` | да | нет |
| `GET /promotions` | да | нет |
| `GET /promotions/{slug}` | да | нет |
| `PATCH /me` | да | нет |
| `POST /me/change-password` | да | нет |
| `GET /cart`, `DELETE /cart`, `PUT /cart/items` | да (2026-06-11) | нет |
| `GET /products/filters`, query `attr` / `attrRange` на `GET /products` | да (GitLab `23cbd8e`) | нет |
| `GET /search` | да (подсказки) | — |
| `GET /products` + `q` | да (страница результатов, W4) | `GET /search/products` в client — **не канон** |
| `GET /claims`, `POST /claims` | да (канон стенда) | нет (`/claims` в post-MVP yaml) |
| `GET /orders`, `GET /orders/{id}`, `POST /orders/{id}/repeat` | да (2026-06-11); `?search=` на списке — да | нет |
| `GET /documents`, `GET /documents/{id}/download` | да (2026-07-09 спека; routes на стенде с `d2f9b1e` / 2026-07-27) | `GET /orders/{id}/documents` в client — отдельно |
| `CartItem`: `lineTotal`, `unitsPerBox`, `amountPerBox`, `discounted*`, `unitPrice` (за штуку) | да (канон стенда) | устар. в client: `packagingMode*` — **снято** с требований ЧТЗ 01 (2026-08-07) |
| Схемы `ProductAttributes`, `unitsPerBox` в карточке/листинге | да (2026-06-11) | нет / частично |

**Канон изменений:**

- текст **`public-http-openapi.yaml`**, **`1c-http-openapi.yaml`**, **`incoming-hooks.md`** → вносить в **GitLab `docs/`**, затем обновить копии в аналитике;
- **`openapi_client_mvp.yaml`** и **`openapi_1c_inbound_mvp.yaml`** — по договорённости продукта/архитектуры здесь или в коде тестов; затем при необходимости `ruby tools/merge_openapi_mvp.rb`.

## Матрицы готовности стенда (снимок GitLab)

| Документ | Назначение |
|----------|------------|
| [`Backend_готовность_MVP_матрица.md`](Backend_готовность_MVP_матрица.md) | ЧТЗ ↔ бэкенд Laravel; блокеры B1–B6 |
| [`Frontend_готовность_MVP_матрица.md`](Frontend_готовность_MVP_матрица.md) | ЧТЗ ↔ Nuxt; блокеры F1–F6 |
| [`Аудит_готовности_2026-08-07.md`](../Аудит/Аудит_готовности_2026-08-07.md) | Актуальный сводный аудит бэк + фронт + 1С |
| [`архив/Аудит_готовности_2026-07-17.md`](../архив/Аудит_готовности_2026-07-17.md) | Предыдущий снимок (`0802839`) |
| [`архив/Аудит_готовности_2026-07-06.md`](../архив/Аудит_готовности_2026-07-06.md) | Исторический снимок готовности (`f497379`) |
| [`Задание_создание_заказа_MVP.md`](Задание_создание_заказа_MVP.md) | Постановка для бэка и 1С: корзина → `POST /orders` → `post_orders` |
| [`Задание_фронтенд_MVP.md`](Задание_фронтенд_MVP.md) | Постановка фронта: приоритеты F1–F6 |
| [`Чеклист_1С_sync.categories.md`](Чеклист_1С_sync.categories.md) | Приёмка `sync.categories` |
| [`Чеклист_1С_sync.documents.md`](Чеклист_1С_sync.documents.md) | Приёмка `sync.documents` |
| [`Чеклист_1С_sync.orders_and_statuses.md`](Чеклист_1С_sync.orders_and_statuses.md) | `post_orders` + inbound статусы |

Обновлять коммит в шапке матриц после `git fetch gitlab`.
