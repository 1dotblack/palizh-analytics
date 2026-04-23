# OpenAPI: интеграция 1С → платформа

Контракт в YAML: [`openapi_1c_inbound_mvp.yaml`](openapi_1c_inbound_mvp.yaml). **Принятые решения** (тимлид): [`Принятые_решения_API_интеграция_1С.md`](Принятые_решения_API_интеграция_1С.md). Черновик с примерами JSON: [`входящие/incoming-hooks.md`](../входящие/incoming-hooks.md).

Публичные `GET` каталога, корзина, заказы — [`openapi_client_mvp.yaml`](openapi_client_mvp.yaml), пояснения в [`openapi_mvp_catalog_product.md`](openapi_mvp_catalog_product.md). **Сводка методов и этапов** — [`1C_API_контракт_и_этапы.md`](1C_API_контракт_и_этапы.md). См. [`OpenAPI_индекс.md`](OpenAPI_индекс.md).

**Вызовы бэкенда к HTTP 1С** (заказ, документ) — [`1c-http-openapi.yaml`](1c-http-openapi.yaml), то же в черновике: [`входящие/1c-http-openapi.yaml`](../входящие/1c-http-openapi.yaml).

**Обучение** с 1С **не** интегрируется; программы/заявки — в [`openapi_mvp_полный_черновик.yaml`](openapi_mvp_полный_черновик.yaml) (тег `Training`), **не** в `openapi_client_mvp.yaml`.

---

## 1. Аутентификация

| Механизм | Описание |
|----------|----------|
| `X-Palizh-Signature` | HMAC-SHA256 по **сырому** телу запроса; формат `t=<unix_ts>, v1=<hex>` |
| IP allowlist | Исходящие IP контура 1С занесены на платформе |
| Схема в OpenAPI | `oneCIntegrationHmac` (apiKey в header) |

Подробности: [`Интеграция_1С.md`](Интеграция_1С.md) §4.3–§4.4.

---

## 2. Endpoint (канон)

| Метод | Path | Назначение |
|-------|------|------------|
| `POST` | `/exchange` | **Единый** вход: поля `event` + `payload`. События MVP: `sync.products`, `sync.counterparties`, `sync.categories`. Успех: **202** + тело `ExchangeAcceptedResponse` (см. YAML). |

Идемпотентность пакетов, размеры payload, ретраи — по мере внедрения; базовая подпись тела **обязательна** (см. принятые решения).

---

## 3. Схемы (components/schemas)

| Схема | Назначение |
|-------|------------|
| `OneCExchangeRequest` | `event` (строка, перечисление в YAML), `payload` (object или array) |
| `ExchangeAcceptedResponse` | `ok: true` при 202 (можно расширить jobId и т.д.) |
| `ErrorResponse`, `ValidationErrorResponse` | Ошибки |

---

## 4. Связь с бизнес-документами

- ЧТЗ: [`ЧТЗ/09_интеграция_1С.md`](../ЧТЗ/09_интеграция_1С.md) (инициатор 1С, последовательные пакеты, дельты).
- Техническая архитектура: [`Интеграция_1С.md`](Интеграция_1С.md).

---

## 5. Атрибуты товара в публичном API

Схема `ProductAttribute` в `openapi_client_mvp.yaml`: в ответе по товару достаточно `code`, `name`, `value` — см. [`openapi_mvp_catalog_product.md`](openapi_mvp_catalog_product.md) §1. Импорт из 1С в теле `sync.products` согласуется с полями в `входящие/incoming-hooks.md` и маппингом.
