# OpenAPI MVP: интеграция 1С → платформа

Дополнение к [`openapi_mvp.yaml`](openapi_mvp.yaml): **входящие** server-to-server методы, которые вызывает **1С** на API платформы. Публичные `GET /catalogs`, `GET /products` и т.д. описаны в [`openapi_mvp_catalog_product.md`](openapi_mvp_catalog_product.md).

**Не входит в этот файл:** вызовы **платформы к HTTP-сервисам 1С** (например `GET` контрагента по одному `GUID`, `GET categories` в 1С) — это клиентские запросы бэкенда к 1С, контракт задаётся на стороне 1С.

---

## 1. Аутентификация

| Механизм | Описание |
|----------|----------|
| `X-Palizh-Signature` | HMAC-SHA256 по сырому телу запроса; формат `t=<unix_ts>, v1=<hex>` |
| IP allowlist | Исходящие IP контура 1С занесены на платформе |
| Схема в OpenAPI | `oneCIntegrationHmac` (apiKey в header) |

Подробности: [`Интеграция_1С.md`](Интеграция_1С.md) §4.3–§4.4.

---

## 2. Endpoints (канонический контракт в YAML)

| Метод | Path | Назначение |
|-------|------|------------|
| `POST` | `/integrations/1c/events` | События: статус заказа, документы, доставка, контрагент и т.д. Тело — `OneCEventEnvelope`. Идемпотентность по `event_id`. |
| `POST` | `/integrations/1c/catalog/sync` | Импорт каталога: `mode=full` (первая полная выгрузка или пересбор) или `mode=delta` (только изменения). Тело `payload` — JSON дерева/пакета по согласованию с 1С. |
| `PUT` | `/integrations/1c/orders/{oneCOrderGuid}` | Опциональный упрощённый путь для обкатки: push статуса заказа без полного envelope. В проде предпочтительно событие `order.status_changed` в `POST .../events`. |

Ответы успеха: `200` / `202` + `IntegrationInboundAcceptedResponse` (и `OneCCatalogSyncAcceptedResponse` для каталога).

---

## 3. Схемы (components/schemas)

| Схема | Назначение |
|-------|------------|
| `OneCEventEnvelope` | `event_id`, `event_type`, `occurred_at`, `source: 1c`, `object_ref`, `payload` |
| `OneCObjectRef` | Гибкая ссылка на сущность (`type`, `one_c_guid`, `platform_order_id`, …) |
| `OneCCatalogSyncRequest` | `mode`, опционально `batch_id`, `payload` (произвольный объект от 1С) |
| `OneCCatalogSyncAcceptedResponse` | `jobId`, `status` |
| `OneCOrderStatusPushRequest` | `status`, опционально `platform_order_id`, `payment_status`, `occurred_at` |
| `IntegrationInboundAcceptedResponse` | `ok`, опционально `eventId`, `jobId` |

---

## 4. Связь с бизнес-документами

- ЧТЗ: [`ЧТЗ/09_интеграция_1С.md`](../ЧТЗ/09_интеграция_1С.md) §4.1 (full/delta, инициатор 1С).
- Техническая архитектура: [`Интеграция_1С.md`](Интеграция_1С.md).
- Задание 1С: [`Задание_1С_разработчику.md`](Задание_1С_разработчику.md).

---

## 5. Атрибуты товаров в публичном API

Схема `ProductAttribute` в `openapi_mvp.yaml`: в ответе по товару достаточно `code`, `name`, `value` (и опционально `valueType`). Отдельный ресурс «справочник всех атрибутов» для MVP **не обязателен** — см. [`openapi_mvp_catalog_product.md`](openapi_mvp_catalog_product.md) §1.
