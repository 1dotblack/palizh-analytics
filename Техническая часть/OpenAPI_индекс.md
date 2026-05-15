# OpenAPI Palizh: какие файлы для чего

Контракты **разделены по назначению** (клиент ↔ бэкенд и server-to-server с 1С). Монолитный `openapi_mvp.yaml` **снят**; копия последнего объединённого варианта — в `архив/openapi_mvp_monolith_2026-04-17.yaml`.

## Канон источников (GitLab разработки)

В репозитории **[gitlab.com/nutnet/palizh](https://gitlab.com/nutnet/palizh)** каталог **`docs/`** — первоисточник по соответствующим артефактам. После `git fetch gitlab` копии в этом репозитории аналитики должны совпадать с:

- `docs/public-http-openapi.yaml` ↔ `Техническая часть/public-http-openapi.yaml`
- `docs/1c-http-openapi.yaml` ↔ `Техническая часть/1c-http-openapi.yaml` и **`входящие/1c-http-openapi.yaml`** (идентичные файлы)
- `docs/incoming-hooks.md` ↔ **`входящие/incoming-hooks.md`**

Правки этих четырёх путей в аналитике выполняются **переносом из GitLab** (или явным решением изменить канон в GitLab и затем синхронизировать сюда).

**Замечание по снимку коду:** описание в `public-http-openapi.yaml` может **опережать** регистрацию маршрутов в `backend/app/Modules/Api/` (там возможна заготовка). Имеет смысл периодически сверять спеку с фактическими `Route::` контроллерами и с фронтом на стенде.

| Файл | Назначение | Кто потребляет |
| ---- | ---------- | -------------- |
| [`openapi_client_mvp.yaml`](openapi_client_mvp.yaml) | **Продуктовый контракт** витрины и ЛК (онбординг, auth, профиль, каталог, корзина, заказы, документы и т.д.) — живёт в репозитории аналитики; описывает целевой REST и **Bearer** там, где договорён токен. **Не** смешивать с каноном стенда: выравнивать относительно [`public-http-openapi.yaml`](public-http-openapi.yaml) по мере созревания бэкенда. | Продукт, фронт, мобилка — целевая модель API |
| [`openapi_1c_inbound_mvp.yaml`](openapi_1c_inbound_mvp.yaml) | Формальное OpenAPI для **`POST /exchange`** (HMAC, событие + payload). Согласовать с GitLab‑модулем `Exchange` и с **`входящие/incoming-hooks.md`**. При расхождениях с кодом править здесь только после решения архитектуры (или актуализировать код в GitLab). | Разработка 1С, контрактные тесты inbound |
| [`1c-http-openapi.yaml`](1c-http-openapi.yaml) | **Исходящие вызовы платформа → HTTP-сервисы 1С** (`POST /post_orders`, `GET /get_documents` и т.д.). **Basic** и сеть — на стороне заказчика; дубликат для удобства — см. также [`входящие/1c-http-openapi.yaml`](../входящие/1c-http-openapi.yaml). **Канон текста файла:** `gitlab/.../docs/1c-http-openapi.yaml`. | Бэкенд платформы, разработка 1С (публикации) |
| [`public-http-openapi.yaml`](public-http-openapi.yaml) | **Контракт публичного HTTP API** для стенда/реализации (часто SPA + Laravel Sanctum: cookie, CSRF, см. описание операций и `servers.url`). **Канон текста файла:** `gitlab/.../docs/public-http-openapi.yaml`. | Фронт, контрактные тесты стенда, сверка с продуктовым [`openapi_client_mvp.yaml`](openapi_client_mvp.yaml) |
| [`openapi_mvp_merged.yaml`](openapi_mvp_merged.yaml) | **Объединение** клиент + 1С inbound (генерация скриптом). Для Redoc/Swagger UI, линтеров, которым удобен **один** YAML. **Не править вручную.** | Демо, CI, просмотр «всё в одном» |
| [`openapi_mvp_post_mvp.yaml`](openapi_mvp_post_mvp.yaml) | Post-MVP расширения (претензии, админка, обучение и т.д.). | Планирование |

**События `POST /exchange` (расшифровка payload):** [`входящие/incoming-hooks.md`](../входящие/incoming-hooks.md) — **канон текста:** `gitlab/.../docs/incoming-hooks.md`; примеры `sync.products`, `sync.counterparties`, `sync.categories` и др. Формальное OpenAPI входа — [`openapi_1c_inbound_mvp.yaml`](openapi_1c_inbound_mvp.yaml).

**Скрипты** (каталог `Техническая часть/tools/`):

- `merge_openapi_mvp.rb` — пересобирает `openapi_mvp_merged.yaml` из `openapi_client_mvp.yaml` + `openapi_1c_inbound_mvp.yaml` (запускать после правок двух исходников).
- `split_openapi_client_and_1c.rb` — одноразовая нарезка; источник по умолчанию — архивный монолит, если снова понадобится регенерировать куски из старой одной спеки.

Скрипт **не** включает `public-http-openapi.yaml` и `1c-http-openapi.yaml` — они синхронизируются **только с GitLab `docs/`**.

**Канон изменений:**

- текст **`public-http-openapi.yaml`**, **`1c-http-openapi.yaml`**, **`incoming-hooks.md`** → вносить в **GitLab `docs/`**, затем обновить копии в аналитике;
- **`openapi_client_mvp.yaml`** и **`openapi_1c_inbound_mvp.yaml`** — по договорённости продукта/архитектуры здесь или в коде тестов; затем при необходимости `ruby tools/merge_openapi_mvp.rb`.
