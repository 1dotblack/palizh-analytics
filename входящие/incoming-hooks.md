# Платформа — входящие вебхуки (1С → Платформа)

> **Канон OpenAPI:** [`Техническая часть/openapi_1c_inbound_mvp.yaml`](../Техническая%20часть/openapi_1c_inbound_mvp.yaml) · **принятые решения:** [`Техническая часть/Принятые_решения_API_интеграция_1С.md`](../Техническая%20часть/Принятые_решения_API_интеграция_1С.md)

## Endpoint

`POST /exchange`

## Успешный ответ

`202 Accepted` (запрос принят и будет обработан асинхронно)

## Формат запроса

Content-Type: `application/json`

```json
{
  "event": "sync.products",
  "payload": {}
}
```

### Поля

- **event**: `string` — имя события.
- **payload**: `object | array` — данные события.

## События

Ниже — шаблоны/примеры payload. Состав полей может расширяться.

### sync.products

Описание: синхронизация товаров.

Пример:

```json
{
  "event": "sync.products",
  "payload": [
    {
      "guid": "2b1f3f4a-1a2b-4c3d-8e9f-0123456789ab",
      "parentguid": "3b1f3f4a-1a2b-4c3d-8e9f-0123456789ac",
      "sku": "PLZ-000123",
      "name": "Герметик силиконовый универсальный 280 мл",
      "brand": "Palizh",
      "description": "Подходит для внутренних и наружных работ.",
      "isArchived": false,
      "variants": [
        {
          "guid": "5d3a9d5b-0b2f-4e9c-9f1f-0d3b2a1c9e77",
          "isDefault": true,
          "isArchived": false,
          "sku": "PLZ-000123-10KG",
          "name": "10 кг",
          "stockQty": 12,
          "productionTimeDays": 7,
          "prices": [
            {
              "currency": "RUB",
              "amount": 1290.5,
              "priceTypeCode": "BASE"
            }
          ],
          "attributes": [
            // не решено, просто как возможный вариант решения
            {
              "guid": "11111111-2222-3333-4444-555555555555",
              "name": "Цвет",
              "type": "list",
              "list_values": [
                {
                  "guid": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                  "name": "Красный"
                }
              ],
              "value": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
            },
            {
              "guid": "333333-2222-3333-4444-555555555555",
              "name": "Подходит",
              "type": "bool",
              "value": true
            }
          ],
          "images": [
            {
              "fileName": "product_1.jpg",
              "contentType": "image/jpeg",
              "dataBase64": "/9j/4AAQSkZJRgABAQAAAQABAAD/"
            }
          ]
        }
      ]
    }
  ]
}
```

### sync.counterparties

Описание: синхронизация контрагентов.

Пример:

```json
{
  "event": "sync.counterparties",
  "payload": [
    {
      "guid": "6f9619ff-8b86-d011-b42d-00c04fc964ff",
      "name": "ООО \"Ромашка\"",
      "inn": "7707083893",
      "kpp": "770701001",
      "legalAddress": "109012, г. Москва, ул. Примерная, д. 1",
      "paymentTerms": {
        "priceTypeCode": "B2B_BASE",
        "paymentMode": "postpayment",
        "defermentDays": 14,
        "creditLimit": 250000,
        "hasPostpayAccess": true
      }
    }
  ]
}
```

### sync.categories

Описание: синхронизация категорий.

Payload: массив категорий.

Поля категории:

- **guid**: `uuid` — GUID категории в 1С.
- **parentGuid**: `uuid | null` — GUID родительской категории (null для корневых).
- **name**: `string` — наименование категории.
- **catalogs**: `string[]` — коды каталогов, в которых доступна категория.

Пример:

```json
{
  "event": "sync.categories",
  "payload": [
    {
      "guid": "8b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a",
      "parentGuid": null,
      "name": "Клеи и герметики",
      "catalogs": ["retail", "wholesale"]
    },
    {
      "guid": "9b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1b",
      "parentGuid": "8b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a",
      "name": "Герметики",
      "catalogs": ["retail"]
    }
  ]
}
```
