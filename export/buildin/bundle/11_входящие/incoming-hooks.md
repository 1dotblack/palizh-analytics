<!-- buildin-source: входящие/incoming-hooks.md -->

# Платформа - входящие вебхуки (1С -> Платформа)

**Канон:** текст синхронизирован с GitLab `docs/incoming-hooks.md`. **Имена `event` для реализованных методов на стенде — только как в GitLab** (решение 2026-06-02). Старые имена аналитики (`sync.item_types`, `sync.characteristics`, `sync.stock`) **не использовать**.

**Модель каталога и ER:** [`Техническая часть/Модель_данных_каталог_1С_обмен.md`](../Техническая%20часть/Модель_данных_каталог_1С_обмен.md). **Формальные typed-схемы payload (каталог):** [`openapi_1c_inbound_mvp.yaml`](../Техническая%20часть/openapi_1c_inbound_mvp.yaml) v0.4.0.

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
      "typeGuid": "7b1f3f4a-1a2b-4c3d-8e9f-0123456789ff",
      "parentGuid": "9b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1b",
      "counterpartiesGuid": null,
      "sku": "PLZ-000123",
      "name": "Герметик силиконовый универсальный 280 мл",
      "brand": "Palizh",
      "description": "Подходит для внутренних и наружных работ.",
      "productionTimeDays": 7,
      "unitsPerBox": 12,
      "attributes": [
        {
          "code": "compatibility",
          "values": [
            { "value": "Ложка", "subvalue": "compatible" },
            { "value": "Вилка", "subvalue": "unknown" }
          ]
        },
        {
          "code": "worktype",
          "values": [
            { "value": "Внутренние" },
            { "value": "Наружные" }
          ]
        },
        {
          "code": "surface",
          "values": [
            { "value": "Дерево" },
            { "value": "Бетон" }
          ]
        },
        {
          "code": "special",
          "values": [
            { "value": "XXX" },
            { "value": "YYY" }
          ]
        },
        {
          "code": "tintingMethod",
          "values": [
            { "value": "Подходит для ручного" }
          ]
        },
        {
          "code": "density",
          "values": [
            { "value": 1.25 }
          ]
        }
      ],
      "marketplaceUrls": [
        {
          "type": "ozon",
          "url": "https://www.ozon.ru/product/beysbolka-dlya-malchika-s-setkoy-3957463766/"
        },
        {
          "type": "wb",
          "url": "https://www.wildberries.ru/catalog/916768299/detail.aspx"
        }
      ],
      "isArchived": false,
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
```

### sync.product-attributes

Описание: синхронизация справочника атрибутов товаров (используются для фильтров и отображения на сайте).

Поля:

- **code**: `string` — идентификатор/код атрибута. уникальный
- **label**: `string` — название атрибута для вывода на сайте.
- **valueType**: `string` — тип значения (`string|number|bool`).
- **filterType**: `string` — тип фильтра (`select|range|boolean|none`).
- **unit**: `string|null` — единица измерения.
- **isFilterable**: `boolean` — показывать ли атрибут в фильтрах.
- **isMulti**: `boolean` — может ли у товара быть несколько значений данного аттрибута (например, два типа работ - наружные и внутренние).
- **categories**: `array` — список GUID категорий, в которых атрибут актуален. Для всех категорий: `["*"]`.
- **subvalueOptions**: `object|null` — словарь подзначений (например, для "совместимости").

Пример:

```json
{
  "event": "sync.product-attributes",
  "payload": [
    {
      "code": "compatibility",
      "label": "Совместимость",
      "valueType": "string",
      "filterType": "select",
      "unit": null,
      "isFilterable": true,
      "isMulti": true,
      "categories": ["*"],
      "subvalueOptions": {
        "compatible": "Совместимый",
        "unknown": "Требуется проверка совместимости"
      }
    },
    {
      "code": "worktype",
      "label": "Типы работ",
      "valueType": "string",
      "filterType": "select",
      "unit": null,
      "isFilterable": true,
      "isMulti": true,
      "categories": ["*"]
    },
    {
      "code": "surface",
      "label": "Обрабатываемая поверхность",
      "valueType": "string",
      "filterType": "select",
      "unit": null,
      "isFilterable": true,
      "isMulti": true,
      "categories": ["*"]
    },
    {
      "code": "special",
      "label": "Специальные свойства",
      "valueType": "string",
      "filterType": "select",
      "unit": null,
      "isFilterable": true,
      "isMulti": true,
      "categories": ["*"]
    },
    {
      "code": "tintingMethod",
      "label": "Способ колерования",
      "valueType": "string",
      "filterType": "select",
      "unit": null,
      "isFilterable": true,
      "isMulti": true,
      "categories": ["*"]
    },
    {
      "code": "density",
      "label": "Плотность",
      "valueType": "number",
      "filterType": "range",
      "unit": "г/см3",
      "isFilterable": true,
      "isMulti": false,
      "categories": ["9b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1b"]
    }
  ]
}
```

### sync.product-types

Описание: синхронизация типов товаров.

Пример:

```json
{
  "event": "sync.product-types",
  "payload": [
    {
      "guid": "7b1f3f4a-1a2b-4c3d-8e9f-0123456789ff",
      "name": "Краски"
    }
  ]
}
```

### sync.product-type-characteristics

Описание: синхронизация характеристик типов товаров.

Пример:

```json
{
  "event": "sync.product-type-characteristics",
  "payload": [
    {
      "guid": "5d3a9d5b-0b2f-4e9c-9f1f-0d3b2a1c9e77",
      "typeGuid": "7b1f3f4a-1a2b-4c3d-8e9f-0123456789ff",
      "name": "10 кг",
      "isDefault": true,
      "isArchived": false
    }
  ]
}
```

### sync.stocks

Описание: синхронизация остатков.

Пример:

```json
{
  "event": "sync.stocks",
  "payload": [
    {
      "productGuid": "2b1f3f4a-1a2b-4c3d-8e9f-0123456789ab",
      "characteristicGuid": "5d3a9d5b-0b2f-4e9c-9f1f-0d3b2a1c9e77",
      "stockQty": 12
    }
  ]
}
```

### sync.prices

Описание: синхронизация цен.

Payload: массив цен.

Поля элемента:

- **productGuid**: `uuid`
- **characteristicGuid**: `uuid`
- **currency**: `string` — например `RUB`.
- **amount**: `number` — цена за единицу (штуку) для данного `priceTypeCode`.
- **amountPerBox**: `number | null` — опционально, цена за коробку в той же строке.
- **priceTypeCode**: `string` — код вида цены из справочника видов цен 1С.

**MVP (2026-06-02):** на товар ожидаются **три** вида цены — **розница**, **опт**, **цена за коробку**. Рабочие коды: `RETAIL`, `WHOLESALE`, `BOX`. Поле **`amount`** для `BOX` — **цена за коробку целиком**. См. [`Модель_данных_каталог_1С_обмен.md`](../Техническая%20часть/Модель_данных_каталог_1С_обмен.md).

Пример:

```json
{
  "event": "sync.prices",
  "payload": [
    {
      "productGuid": "2b1f3f4a-1a2b-4c3d-8e9f-0123456789ab",
      "characteristicGuid": "5d3a9d5b-0b2f-4e9c-9f1f-0d3b2a1c9e77",
      "currency": "RUB",
      "amount": 1290.5,
      "amountPerBox": 15486.0,
      "priceTypeCode": "RETAIL"
    },
    {
      "productGuid": "2b1f3f4a-1a2b-4c3d-8e9f-0123456789ab",
      "characteristicGuid": "5d3a9d5b-0b2f-4e9c-9f1f-0d3b2a1c9e77",
      "currency": "RUB",
      "amount": 1180.0,
      "priceTypeCode": "WHOLESALE"
    },
    {
      "productGuid": "2b1f3f4a-1a2b-4c3d-8e9f-0123456789ab",
      "characteristicGuid": "5d3a9d5b-0b2f-4e9c-9f1f-0d3b2a1c9e77",
      "currency": "RUB",
      "amount": 11500.0,
      "priceTypeCode": "BOX"
    }
  ]
}
```

### sync.counterparties

Описание: синхронизация контрагентов.

**Скидка (2026-06-02):** персональная скидка контрагента (`discountPercent` в условиях оплаты) применяется к **розничной** цене (`RETAIL`), если иное не согласовано.

**Персональные цены по номенклатуре:** в `paymentTerms.discounts[]` — `productGuid`, `characteristicGuid`, `price`, `priceBox`. На витрине — `discountedAmount` / `discountedAmountPerBox` в [`public-http-openapi.yaml`](../Техническая%20часть/public-http-openapi.yaml).

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
      "registrationRequestGuid": "aecfadff-305f-4da5-a620-16be5b03d852",
      "paymentTerms": {
        "priceTypeCode": "B2B_BASE",
        "paymentMode": "postpayment",
        "defermentDays": 14,
        "creditLimit": 250000,
        "hasPostpayAccess": true,
        "discounts": [
          {
            "productGuid": "psddefgf-3h5f-yda5-o620-536sdfsdfs52",
            "characteristicGuid": "hewrwecf-j7rf-6dar-1520-bhrthtr5668f",
            "price": 163.54,
            "priceBox": 1630.12
          }
        ]
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
- **isArchived**: `boolean` — признак архивной категории.

Пример:

```json
{
  "event": "sync.categories",
  "payload": [
    {
      "guid": "8b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a",
      "parentGuid": null,
      "name": "Клеи и герметики",
      "isArchived": false,
      "counterparties": "6f9619ff-8b86-d011-b42d-00c04fc964ff"
    },
    {
      "guid": "9b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1b",
      "parentGuid": "8b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a",
      "name": "Герметики",
      "isArchived": false
    }
  ]
}
```
