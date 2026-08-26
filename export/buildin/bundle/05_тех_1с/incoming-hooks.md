<!-- buildin-source: входящие/incoming-hooks.md -->

# Платформа - входящие вебхуки (1С -> Платформа)

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
      "weightKg": 1.25,
      "volumeL": 0.5,
      "boxWeightKg": 10.50,
      "boxSizeCm": {
        "width": 20.00,
        "height": 30.00,
        "length": 40.00
      },
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
          "dataBase64": "\/9j\/4AAQSkZJRgABAQIAHAAcAAD\/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgG\nBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD\/2wBDAQMD\nAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQ\nEBAQEBAQEBAQEBAQEBD\/wAARCABkACEDAREAAhEBAxEB\/8QAHAAAAgIDAQEAAAAA\nAAAAAAAABQkGCAMEBwAC\/8QALRAAAgIBAwMDBAEFAQEAAAAAAQIDBAUGERIAByEI\nEyIJFDFBURcjMmFxFWL\/xAAaAQADAAMBAAAAAAAAAAAAAAACAwQAAQUG\/8QALREA\nAQMDAwEGBgMAAAAAAAAAAQACEQMhMQQSQVEFEyJhccEUMpGhsfAGgeH\/2gAMAwEA\nAhEDEQA\/AFc6fwWV1TnsbpnBVfusnl7cNCnBzVPdnlcJGnJiFXdmA3JAG\/kgdYTF\n1gEpiWhvpedqo4rTa77uZ\/MyTCM00xVeHFewRz5iUyLa9zf4bcePHY78uXxAOJ4W\nG2Fp90\/pYaYr4e9nO0fc3MST08XJLBhMpWgty3ryK7LGttTWSJH2jQFojxO7FiDs\noGrtyia3dhLq6chXusWLpPprwmV1B3+7f0sNUazYg1BTyDorKpEFaQWJ2HIgHjFF\nI22+547AEkA6dhYLJx2msTJRo1Mfj0zF2KpGsKT3VQ2ZkUcVeVlVEMhA3YqiruTs\noHgCXk3dlAAG2GFJGkaAKbVO7Gm+zD2vyP43G4HSKjrWTmC6QpqLT+X0nqDJ6W1B\nU+0ymGuTY+7BzV\/asQuUkTkhKtsykbqSDt4JHVIMiQgwh\/W1iuB9NLt5FqLu3me4\nNtK7x6QxwjrbyyLLHcuc40kVV+LKIY7SkMfBkUgEjkou6LCmk4gKJACCfHQQECKm\nHkHjP4bxt0pzZTGmLpRH1Hu1v9P\/AFD2dSUKIgxetqUWWjMNA166W1\/s2Yw4+Msp\naNbEjDY72hyHkMzaLpbHRbfmVVjpqFNp9BfbmfQHp7wdi7HYiuanll1FYilkjkUL\nMFSuYyn4Vq8UD8WJYM7b7f4qJuUJVncXJ\/cJ6FaRUSLy\/wAiCegciCpv9TvtxDqr\nshV1\/DFXF3ROSjlaaWaRX+ytssEscaDdGYzGo27bbLG2xG5VhpmHwmG7ZSrOqUCe\ntpubGYXGQYqjjYqlWpGsFevUgWKKGFBxjjRB4UKgVdhsPHgAeOlNMBC+5si8Oo6M\nJ+cVhf8AidaL4Wg0lbQ1XRY7LFYO3\/xt0BeEYYQoD6iMzFY7C9yBHXkHPSGYXdtv\n3Sl6DdLgmtBAKSN1YlJsesPUvjdMZTBYbRulr+tLea+5eSKqRTeqkaK5Le78NgrE\nMxYAFCf2OjNHaLGUDnh7pAgfX26\/TF8oRS9YkF7UdrR69je4LZujGstmpDVglMUb\neVcuJOPA\/pt9j+t+kmmVsdVo3vXBgsc8kVntBrWtJHkFxTi8kFUJbZQwibk+4YqQ\n34\/HnoO7PKOUW1x36wmtexHcyllsecNkkwOVpQ01m+5Lh6DFXLqoVQS+23+utGmA\nQja6QUqvp6WrxdxkSTtn2\/1VktIW4aup8CauYnxaF5OFmrBL7scUjfPaRASm\/lSV\n3G4PTi610oC9lGtQZfDd0dKXNBYDS+p9LY4SUpDqOjpawIclYrpIrxT1oCxiQLKn\ntqrMAV8gb+Fkg4RgRlC+6mqKed0BW0VYo61xt\/S8lKfCZW7gZfczktau0RaTcgwn\nky8SeWyqoPnoSQiAJwpt2uwWZs+mjuLqHW+PtT5m3iMxKJ7zsHCJT2Qhf1tt43\/j\npJc15BaZumGm+nZ4ItyqQdOS0z7QemtL697L9ucTksXNZhq6eofclpGjCMacIDq6\n7gHw22\/ROc3b4llOdx25XCdRZnPaCp57FYbKxCnib5kgglginALtsxLMOQ8IngeD\n1zRXcBDV1BpmPqDeoRqbuXn9c4yHC5HLQIlVlf2IIkhUkbHyqgbnwPzv1BUr1XeK\novUUtBpmvAoWIMnnjzVjIb74\/wBMOraUleVJbOm8v8mBAZDVYD\/vkH\/XTOzGkUQT\nbxLlfyJ7TrC1t\/CPdLi67a8wmjdpcZS\/olpHJ5G1nKq1MDhZBNjFAmjVoIyW3\/SH\njxLfoHpzBYylON0KuYnGZ9jNkNa6JysMssCzzWMXCtgytJByVvcjO\/xFniNuW\/Ek\nnfYJe1pyE5j3NwUFkxS4+5DZh1JoHDRIknOxUxMNiRWKDZozHCRx3SQqCeQA2Yk9\nKFNgsAqHais8y55+qlPdmBqfaDVZvZ6a3Nf0llbkX3KcG4tFLuiLuSEHjbc\/gjpd\nRwDmjzQsaXBx8kr\/AKpSE4nsPq3CQ9ie3UNRYoskukMXVZnRPbsMqfJBxALbKU35\nfLlzAPEL1Yy7JapnyHwVsZ2to7OZCCXL6Gx9q8kgKOigEMPwSdgP3v5PjqWplUsX\n3ax2Lp4S\/WwGBwuHtmm6VZDLEGSXYhQAoO3knz+ifwepKwcWEMzwuho3UWV2OriW\nAifRcX15HW0\/2i1ti83ZfJZabQ1+kDBbLipOWadvcLnk49uJhxAPyYHYAbiPTaXa\n0Gu67YIF87hzPQ8yPLkWdtdoN1WqLtG2GOJBMAS0MdFoMXAwQfOAQVp9dVcNNs9I\nGmKWvPR5oJM9NLJYhW+sFotykiEeQsoi7n8qqKihT4CqANth0+m7a2ymqXfdSXN6\nN1Fivar04qV2OKSRjL93KrsGO4HFiQu2\/wDJ8eOpqtQBVUhKBx6L1lfgarPJTpCT\n3EeRbEjfFgAPgvgsPJ35fv8AXUjqw4VQpqF+oDAaf7S+nPW1ypQ\/9O5NjjSazMwW\nRXtOtUyKdjx4rO54j\/IbqSOW\/UwmrVa2Y\/wg+ycfBTLo\/SCPdK+66y5yY79OXvJp\n+726yfbPIQU6+oNOuGqSIsaS3MZJLNNs3kyTGKeeb8BVRZl2DFyQpzxSdu6\/v7\/a\nZ4qrBTmwkxxJiT5TAnrA6K0WXzNR2YNuNj54kHz\/AM\/XUtau0p1Kg4INHnIVk9uC\nOSV3IVF28sT+AANyT1C6uMDKsbSMSVU312d1oa+hF0DHkaL3dQTV5JKXtuZoKkTt\nIZSwbZeUqQqoYeQsh8kAprQNfqNR3zvlbj1x+Dj0nhM1rqdHT90PmJv6enEEZm8w\nBYqhfXeXFWalduY65BkMfbmq2qsqzQTwyFJIpFIKurDyrAgEEeQR1hE2KwGLhdXq\nerb1FU8ZVxC9z789Wly9lLdavZZWYKGYtLGzMzBE3YkseK7k7Dqd2kouyPuU8amq\n3B+wWrkPVF34yVeetZ7gzotiJ4XaClWgfgw2Ozxxqyn+CCCCAQQQD0v4DTzO37lH\n8ZXiN34XMbly3kLc9+\/ams2rMjTTTTOXklkY7szMfLMSSST5JPVYAaIGFMSSZKxd\nbWl\/\/9k=\n"
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
      "priceTypeCode": "B2B_BASE"
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

### sync.documents

Описание: синхронизация документов.

Payload: массив документов.

Поля документа:

- **guid**: `uuid` — GUID документа в 1С.
- **name**: `string` — Название файла
- **type**: `string` - Идентификатор типа документа (agreement / upd / bill)
- **relatedEntityType**: `string` - тип связанной с документом сущности (заказ / контрагент)
- **relatedEntityGuid**: `uuid` - GUID сущности в 1С, к которой привязан документ (заказ / контрагент)
- **file**: `object|null` - отправлять null, если ожидается, что документ будет загружаться "по требованию пользователя" из 1С в момент запроса (не хранится на платформе)
  - **contentType**: `string` - mime-тип файла
  - **dataBase64**: `string` - содержимое файла

Пример:

```json
{
  "event": "sync.documents",
  "payload": [
    {
      "guid": "8b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a",
      "name": "Счет.pdf",
      "type": "bill",
      "relatedEntityType": "order", // заказ
      "relatedEntityGuid": "7b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a", // guid заказа
      "file": {
        "contentType": "application/pdf",
        "dataBase64": "/9j/4AAQSkZJRgABAQAAAQABAAD/"
      }
    },
    {
      "guid": "2a0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a",
      "name": "Упд.pdf",
      "type": "upd",
      "relatedEntityType": "order", // заказ
      "relatedEntityGuid": "7b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a", // guid заказа
      "file": null // нет данных о файле - значит при попытке скачать будем дергать 1С
    },
    {
      "guid": "1b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a",
      "name": "Договор №1234.docx",
      "type": "agreement",
      "relatedEntityType": "counterparty", // контрагент
      "relatedEntityGuid": "6b0c9c9a-1f9f-4edb-8d6b-8a3b2d2c0c1a", // guid контрагент
      "file": {
        "contentType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "dataBase64": "/9j/4AAQSkZJRgABAQAAAQABAAD/"
      }
    }
  ]
}
```
