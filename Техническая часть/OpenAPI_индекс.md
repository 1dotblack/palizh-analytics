# OpenAPI Palizh: какие файлы для чего

Контракты **разделены по назначению** (клиент ↔ бэкенд и server-to-server с 1С). Монолитный `openapi_mvp.yaml` **снят**; копия последнего объединённого варианта — в `архив/openapi_mvp_monolith_2026-04-17.yaml`.

## Канон источников (GitLab разработки)

В репозитории **[gitlab.com/nutnet/palizh](https://gitlab.com/nutnet/palizh)** каталог **`docs/`** — первоисточник по соответствующим артефактам.

**Последняя подтяжка в аналитику:** `gitlab/main` **`f497379`** (2026-07-06) — `public-http-openapi.yaml` (**3661** строк): `/claims`, `/search` (подсказки), `/notifications/*`. Предыдущая: **`23cbd8e`** — filters, `attr`/`attrRange`.

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
| `GET /orders`, `GET /orders/{id}`, `POST /orders/{id}/repeat` | да (2026-06-11) | нет |
| `CartItem`: `packagingMode`, `fullBoxesCount`, `remainderQuantity`, … | да (**2026-06-02**) | да (`CartItem` в client) |
| Схемы `ProductAttributes`, `unitsPerBox` в карточке/листинге | да (2026-06-11) | нет / частично |

**Канон изменений:**

- текст **`public-http-openapi.yaml`**, **`1c-http-openapi.yaml`**, **`incoming-hooks.md`** → вносить в **GitLab `docs/`**, затем обновить копии в аналитике;
- **`openapi_client_mvp.yaml`** и **`openapi_1c_inbound_mvp.yaml`** — по договорённости продукта/архитектуры здесь или в коде тестов; затем при необходимости `ruby tools/merge_openapi_mvp.rb`.
