# Платформа → публикации 1С (1c-http)

Исходный YAML: **`11_1c_http_openapi.yaml`**.

```yaml
openapi: 3.0.3
info:
  title: 1C - HTTP API
  version: 0.1.0
servers:
  - url: http://palitra.udm.ru:8181/demo_2/hs/b2b/
security:
  - basicAuth: []
tags:
  - name: Orders
    description: Заказы
  - name: Documents
    description: Документы
paths:
  /post_orders:
    post:
      operationId: createOrder
      tags:
        - Orders
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/OrderCreateRequest'
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/OrderCreateResponse'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '409':
          description: Conflict (order with same externalGuid already exists)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          $ref: '#/components/responses/InternalServerError'
  /get_documents:
    get:
      operationId: downloadDocument
      tags:
        - Documents
      parameters:
        - name: type
          in: query
          required: true
          schema:
            type: integer
            example: 0
        - name: guid
          in: query
          required: true
          schema:
            type: string
            format: uuid
            example: 9c1b2c3d-4e5f-6789-aaaa-bbbbbbbbbbbb
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/DocumentDownloadResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '404':
          $ref: '#/components/responses/NotFoundError'
        '500':
          $ref: '#/components/responses/InternalServerError'
components:
  securitySchemes:
    basicAuth:
      type: http
      scheme: basic
  responses:
    UnauthorizedError:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    NotFoundError:
      description: Not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    InternalServerError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
  schemas:
    Money:
      type: object
      title: Денежная сумма
      required:
        - currency
        - amount
      properties:
        currency:
          type: string
          description: Валюта (ISO 4217).
          example: RUB
        amount:
          type: number
          description: Сумма.
          example: 1290.5

    OrderCreateRequest:
      type: object
      title: Создание заказа
      description: Запрос на создание заказа в 1С. externalGuid используется для связывания с заказом на платформе и для идемпотентности.
      required:
        - externalGuid
        - counterpartyGuid
        - deliveryAddress
        - items
      properties:
        externalGuid:
          type: string
          format: uuid
          description: GUID заказа на платформе (ключ идемпотентности).
          example: 9c1b2c3d-4e5f-6789-aaaa-bbbbbbbbbbbb
        counterpartyGuid:
          type: string
          format: uuid
          description: GUID контрагента в 1С.
          example: 6f9619ff-8b86-d011-b42d-00c04fc964ff
        deliveryAddress:
          type: string
          description: |
            Адрес доставки одной строкой. С платформы — отформатированное значение DaData
            (`unrestricted_value`, ЧТЗ 01 §4.1.2).
          example: 109012, г. Москва, ул. Примерная, д. 1
        comment:
          type: string
          nullable: true
          description: Комментарий к заказу.
          example: Позвонить за час до доставки
        items:
          type: array
          minItems: 1
          items:
            $ref: '#/components/schemas/OrderCreateItem'

    OrderCreateItem:
      type: object
      title: Позиция заказа
      required:
        - productVariantGuid
        - quantity
      properties:
        productVariantGuid:
          type: string
          format: uuid
          description: GUID варианта товара в 1С.
          example: 5d3a9d5b-0b2f-4e9c-9f1f-0d3b2a1c9e77
        quantity:
          type: integer
          minimum: 1
          description: Количество.
          example: 3
        priceBase:
          allOf:
            - $ref: '#/components/schemas/Money'
          nullable: true
          description: Базовая цена за единицу для сверки.
        priceFinal:
          allOf:
            - $ref: '#/components/schemas/Money'
          nullable: true
          description: Финальная (после скидок) цена за единицу для сверки.

    OrderCreateResponse:
      type: object
      title: Результат создания заказа
      required:
        - orderGuid
      properties:
        orderGuid:
          type: string
          format: uuid
          description: GUID созданного заказа в 1С.
          example: 3fa85f64-5717-4562-b3fc-2c963f66afa6
    DocumentDownloadResponse:
      type: object
      title: Скачивание документа
      required:
        - fileName
        - contentType
        - dataBase64
      properties:
        fileName:
          type: string
          example: invoice_123.pdf
        contentType:
          type: string
          example: application/pdf
        dataBase64:
          type: string
          format: byte
          description: Содержимое файла в base64.
          example: JVBERi0xLjQK
    ErrorResponse:
      type: object
      title: Ошибка
      required:
        - message
      properties:
        message:
          type: string
          example: Unauthorized
        code:
          type: string
          nullable: true
          example: AUTH_REQUIRED
```
