# Матрица готовности бэкенда MVP (ЧТЗ ↔ GitLab)

**Дата снимка:** 2026-06-27  
**Источник кода:** [gitlab.com/nutnet/palizh](https://gitlab.com/nutnet/palizh), ветка **`main`**, коммит **`c313ed4`** (2026-06-26, merge `dev#86350_search`).  
**Источник требований:** ЧТЗ 01–14, канон API — `docs/public-http-openapi.yaml` (копия в аналитике: `Техническая часть/public-http-openapi.yaml`), inbound — `docs/incoming-hooks.md`, исходящий 1С — `docs/1c-http-openapi.yaml`.  
**План работ (ориентир эпиков):** `Backend_план_работ_MVP.md`.

### Легенда статусов

| Статус | Смысл |
|--------|--------|
| **Готово** | Реализовано на стенде, пригодно для стыковки (мелкие расхождения со спекой допустимы, если зафиксированы ниже). |
| **Частично** | Есть код/модели, но неполный контур, расхождение с OpenAPI/ЧТЗ или нет prod-интеграции. |
| **Заглушка** | Каркас (job/listener/route), бизнес-интеграция не доделана (`todo`, лог вместо вызова 1С). |
| **Нет** | В репозитории не найдено. |
| **Post-MVP** | По ЧТЗ вне текущего релиза. |

### Сводка по областям (оценка аналитика)

| Область | Готовность | Комментарий |
|---------|------------|-------------|
| Инфраструктура / CI | **~70%** | Docker, GitLab CI build/deploy, `/up`; YC/NAT/Lockbox — вне репозитория |
| Публичный HTTP API (витрина/ЛК) | **~75%** | Большинство маршрутов `public-http-openapi.yaml` есть в `Modules/Api` |
| Каталог + фильтры | **~80%** | Импорт exchange + `GET /products`, `filters`, `attr`/`attrRange` |
| Корзина / заказ (платформа) | **~65%** | CRUD заказа на платформе есть; синк с 1С — заглушка |
| Inbound 1С `POST /exchange` | **~60%** | Все 8 событий каталога; **нет HMAC/IP**, нет inbox/идемпотентности |
| Outbound 1С | **~15%** | `SendOrderJob` / `SendRegistrationRequestJob` — `todo real send`; клиента HTTP 1С нет |
| Документы ЛК | **~0%** | `GET /get_documents` / API документов в ЛК — нет |
| Email-уведомления | **~25%** | Классы `Notification` + шаблоны в settings; рассылка по событиям почти не подключена |
| Поиск по каталогу | **~0%** (роут в спеке **2026-06-02**) | `GET /search/products` в `public-http-openapi.yaml`; реализация на стенде — уточнить (ветка search) |
| Админка (Filament) | **~85%** | Контент, пользователи, настройки, обучение, баннеры, акции |
| RBAC ЛК | **~40%** | Роли в модели; policies в основном на `users`; разделы ЛК не разграничены |
| Тесты / контрактные | **~5%** | `ExampleTest` |

---

## 1. Матрица по блокам ЧТЗ и эпикам бэка

| Блок | ЧТЗ / артефакт | Требование MVP (кратко) | GitLab `main` | Статус | Пробел / расхождение |
|------|----------------|-------------------------|---------------|--------|----------------------|
| **0** | Инфра | Laravel, PG, Redis, Docker, CI, health | `backend/`, `docker-compose*.yml`, `.gitlab-ci.yml`, `/up` | **Частично** | Прод YC, egress IP, Sentry — не верифицированы по коду |
| **A** | 13, Backend | Версия API, ошибки, correlation id | `Constant::API_PREFIX`, exception render для API | **Частично** | Явный `Correlation-Id` middleware не проверен |
| **A** | 05, 07 | Auth Sanctum: login/register/reset/me | `AuthController`, `auth:sanctum`, `statefulApi()` | **Готово** | Активация только после контрагента из 1С — логика `checkCounterpartyIsNeeded` |
| **A** | 07 | RBAC: директор / закупщик / бухгалтер | `UserRole`, `UserPolicy` (только users) | **Частично** | Нет gates на заказы/документы/корзину по ролям (ЧТЗ 07 §4.6) |
| **A** | — | `GET /csrf-cookie` | Не в `api.php`; Sanctum stateful | **Частично** | В спеке есть путь; уточнить с фронтом (cookie CSRF) |
| **06** | 06 | Категории, товары, карточка | `CategoryController`, `ProductController` | **Готово** | Персональная номенклатура: фильтр `counterparty_guid` в запросе |
| **06** | 06 §4.2.0 | `GET /products/filters`, `attr`/`attrRange` | `ProductController::filters`, `ProductsListFilter` | **Готово** | `filters` без `categorySlug` → пустой список (by design в коде) |
| **06** | 06 | Цены, скидки, коробка | `ProductPrice`, `CounterpartyResource`, импорт `sync.prices` | **Частично** | Отображение по ЧТЗ §4.2.4 — зона фронта; скидки на уровне API — сверить с `discountedAmount` в спеке |
| **06** | 12 | Баннеры, акции, новости, страницы | API read + Filament CRUD | **Готово** | |
| **06** | 12 | `GET /settings` (порог доставки и др.) | `SettingController`, `SettingsRegistry` | **Готово** | |
| **01** | 01 | Корзина | `CartController` (`GET`, `PUT items`, `DELETE`) | **Готово** | Путь `PUT /cart/items` совпадает со спекой |
| **01** | 01 | Оформление заказа | `OrderController::store`, `OrderService` | **Частично** | Создание на платформе; передача в 1С — заглушка |
| **01** | 01 | Заказ из файла | — | **Post-MVP** | ЧТЗ 01 |
| **08** | 08 | История заказов, карточка, repeat | `OrderController` index/view/repeat | **Готово** | 6 статусов в `OrderStatus` enum совпадают с ЧТЗ |
| **08** | 08 | `integrationSyncState` / сбой синка | `OrderSyncStatus` в модели | **Частично** | **Не отдаётся** в `OrderResource` / OpenAPI на стенде |
| **08** | 08 | Delivery-блок (самовывоз, ТК) | `delivery_type`, `delivery_info` в заказе | **Частично** | Наполнение из 1С inbound-событий заказа — **нет** |
| **08** | 08 | Поиск по списку заказов | `?search=` в `OrderController::index` | **Частично** | В спеке `public-http` для заказов search не описан; в коде есть |
| **02** | 02 | Документы в ЛК (счёт, УПД, ТТН…) | — | **Нет** | Нет `DocumentsController`, нет вызова `get_documents` |
| **03** | 03 | Данные доставки / водитель из 1С | Поля в заказе | **Частично** | Нет inbound-обновления статусов/delivery из 1С |
| **04** | 04 | Претензии по заказу | `ClaimController` | **Частично** | Роут **`/api/claims`**, в OpenAPI — **`/claim`** (singular) |
| **01** | 01 | Нестандартная заявка | Только `Notification` классы | **Нет** | Нет API сохранения заявки |
| **05** | 05 | Регистрация «Стать клиентом» | `register`, `RegistrationRequest`, `SendRegistrationRequestJob` | **Заглушка** | Job: `// todo real send` |
| **05** | 07 | Управление пользователями ЛК | `UserController` store/patch | **Частично** | Только директор; нет `GET /users` list в роутах |
| **07** | 07 | Профиль / контрагент | `me`, `CounterpartyResource` | **Частично** | Нет бонусов в API (ЧТЗ 07 MVP — баланс из 1С) |
| **09** | 09 | Inbound `POST /exchange` | `ExchangeController`, 8 handlers | **Частично** | Ответ `202` текст `OK`, не JSON; **нет HMAC/IP** middleware |
| **09** | 09 | События каталога `sync.*` | Все 8 из `incoming-hooks.md` в `WebhookHandlerFactory` | **Готово** | Jobs async; идемпотентность/inbox — **нет** |
| **09** | 09 | Outbound `post_orders` | `SendOrderJob` | **Заглушка** | Нет HTTP-клиента 1С |
| **09** | 09 | Inbound статусы заказа / документы | — | **Нет** | События не в factory |
| **10** | 10 | Email по событиям MVP | 15+ классов `*Notification`, email в `SettingsRegistry` | **Частично** | Подключены в основном register/reset password |
| **11** | 11 | Поиск по каталогу (`GET /search/products`) | — | **Нет** / уточнить | Платформенный full-text/PG; **не Ensi** (ЧТЗ 11). Ветка `dev#86350_search` — вероятно фронт |
| **14** | 14 | Обучение: каталог + заявка | `Training/*Controller` | **Готово** | Заявка с throttle; список заявок — auth |
| **12** | 12 | Админка | Filament resources (баннеры, новости, акции, страницы, программы, users, settings) | **Готово** | Отдельного REST admin API нет (не требуется) |
| **12** | 12 | Маршрутизация email по типам обращений | Settings `email:*` | **Частично** | Шаблоны в БД; триггеры на claim/training — не везде |
| **06** | 06 | Избранное | `FavoriteProductController` | **Готово** | |
| **—** | OpenAPI | `GET /users/{id}` | Только `PATCH /users/{user}` | **Частично** | GET по id в спеке, в роутах нет |

---

## 2. Inbound 1С — детализация

| Событие | ЧТЗ / hooks | Handler + Job | Статус |
|---------|-------------|---------------|--------|
| `sync.product-attributes` | 06, 09 | `SyncProductAttributesHandler` → `ImportProductAttributesJob` | **Готово** |
| `sync.product-types` | 09 | `SyncProductTypesHandler` → `ImportProductTypesJob` | **Готово** |
| `sync.product-type-characteristics` | 09 | `SyncProductTypeCharacteristicsHandler` → job | **Готово** |
| `sync.products` | 06, 09 | `SyncProductsHandler` → `ImportProductJob` | **Готово** |
| `sync.stocks` | 09 | `SyncStocksHandler` → `ImportStocksJob` | **Готово** |
| `sync.prices` | 06, 09 | `SyncPricesHandler` → `ImportPricesJob` | **Готово** |
| `sync.categories` | 06, 09 | `SyncCategoriesHandler` → `ImportCategoriesJob` | **Готово** |
| `sync.counterparties` | 05, 09 | `SyncCounterpartiesHandler` → `ImportCounterpartyJob` | **Готово** |
| Заказы / статусы / документы | 08, 09, 02 | — | **Нет** |

**Безопасность exchange (ЧТЗ 09, `Интеграция_1С.md` §4.3):** HMAC `X-Palizh-Signature`, IP allowlist — **не реализованы** в `ExchangeController` / middleware (поиск по коду — пусто).

---

## 3. Публичный API: спека vs роуты

Канон: **34 path** в `docs/public-http-openapi.yaml`. Реализация: `backend/app/Modules/Api/Routes/api.php` + `Modules/Exchange/Routes/web.php`.

| Path (спека) | Реализация | Статус |
|--------------|------------|--------|
| `/auth/*`, `/me/*` | Да | **Готово** |
| `/csrf-cookie` | Неявно (Sanctum) | **Частично** |
| `/banners`, `/settings`, `/pages/{slug}` | Да | **Готово** |
| `/news`, `/promotions` | Да | **Готово** |
| `/categories`, `/products`, `/products/filters` | Да | **Готово** |
| `/cart`, `/cart/items` | Да | **Готово** |
| `/favorites` | Да | **Готово** |
| `/orders`, `/orders/{id}`, `/orders/{id}/repeat` | Да | **Готово** |
| `/claim` | **`/claims`** (мн. ч.) | **Расхождение** — **канон аналитики:** `/claim` (`ЧТЗ 04` §5.4, `public-http-openapi.yaml`); бэкенд — выровнять роут |
| `/training/*` | Да | **Готово** |
| `/users`, `/users/{id}` | POST + PATCH only | **Частично** |
| Поиск по каталогу (`GET /search/products`) | В спеке **2026-06-02**; в коде — **уточнить** | **Частично** |
| Документы ЛК | Нет | **Нет** |
| `POST /exchange` | Да (`/exchange`, не под `/api`) | **Частично** |

---

## 4. Критический путь до «MVP готов к приёмке с 1С»

| # | Блокер | Связь с реестром | Влияние |
|---|--------|------------------|---------|
| 1 | HTTP-клиент 1С: `post_orders`, `get_documents` | №18, №47–48 | Заказ и документы не замыкают контур |
| 2 | Реальная отправка заказа (`SendOrderJob`) | №18, №37 | Заказ «создан» только на платформе |
| 3 | Inbound статусы заказа + delivery из 1С | №18, №40 | ЛК не обновляется из 1С |
| 4 | HMAC + allowlist на `/exchange` | №48 | Безопасность приёмки |
| 5 | Идемпотентность exchange | №37 | Риск дублей при ретраях 1С |
| 6 | Email-триггеры по ЧТЗ 10 | №33 (закрыт канал) | Операционные письма не уходят |
| 7 | API документов ЛК | №18, №49 | ЧТЗ 02 не закрыт |
| 8 | Поиск по каталогу (реализация на стенде) | №34 (номенклатура контрагента post-MVP) | ЧТЗ 11 |
| 9 | Выравнивание `/claim` ↔ `/claims` | — | Контрактные тесты / фронт |

---

## 5. Рекомендуемые следующие шаги (для бэклога)

1. **Закрыть контур заказа:** `post_orders` + поля `integrationSyncState` в API + inbound статусы (минимальный набор).
2. **Защита `/exchange`:** middleware HMAC + IP; JSON `{"ok":true}`; таблица inbox.
3. **Документы:** прокси `get_documents` + метаданные в ЛК.
4. **Претензии:** унифицировать path со спекой (`/claim` или обновить OpenAPI).
5. **Уведомления:** подключить listeners на `NewOrder`, claim, training, смену статуса.
6. **Контрактные тесты:** golden files по `incoming-hooks.md` + smoke по `public-http-openapi.yaml`.

---

*Документ аналитики; при следующей подтяжке GitLab обновить коммит в шапке и пересмотреть статусы. Не заменяет трекер команды.*
