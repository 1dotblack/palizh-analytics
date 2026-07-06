# Матрица готовности бэкенда MVP (ЧТЗ ↔ GitLab)

**Дата снимка:** 2026-07-06  
**Источник кода:** [gitlab.com/nutnet/palizh](https://gitlab.com/nutnet/palizh), ветка **`main`**, коммит **`f497379`** (2026-07-03, merge `feature/86543`).  
**Источник требований:** ЧТЗ 01–14, канон API — `docs/public-http-openapi.yaml` (копия в аналитике: `Техническая часть/public-http-openapi.yaml`, **подтянуто 2026-07-06**), inbound — `docs/incoming-hooks.md`, исходящий 1С — `docs/1c-http-openapi.yaml`.  
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
| Публичный HTTP API (витрина/ЛК) | **~80%** | 39 path в `public-http-openapi.yaml`; большинство маршрутов в `Modules/Api` |
| Каталог + фильтры | **~80%** | Импорт exchange + `GET /products`, `filters`, `attr`/`attrRange` |
| Корзина / заказ (платформа) | **~60%** | CRUD заказа есть; **расчёт `lineTotal` по ЧТЗ 01 §4.2.4 не реализован**; синк с 1С — заглушка |
| Inbound 1С `POST /exchange` | **~60%** | Все 8 событий каталога; **нет HMAC/IP**, нет inbox/идемпотентности |
| Outbound 1С | **~15%** | `SendOrderJob` — `// todo real send`; HTTP-клиента 1С нет |
| Документы ЛК | **~5%** | Миграция `documents`; API ЛК и `get_documents` — **нет** |
| Email / in-app уведомления | **~40%** | `NotificationController` + OpenAPI `/notifications`; email-триггеры по ЧТЗ 10 — частично |
| Поиск по каталогу | **~85%** | `GET /search` (подсказки) + **`GET /products?q=`** (страница результатов, W4) — **готово** на `f497379` |
| Претензии | **~85%** | **`GET/POST /claims`** — OpenAPI и код **совпадают** |
| Админка (Filament) | **~85%** | Контент, пользователи, настройки, обучение, баннеры, акции |
| RBAC ЛК | **~40%** | Роли в модели; policies в основном на `users`; разделы ЛК не разграничены |
| Тесты / контрактные | **~5%** | `ExampleTest` |

---

## 0. Согласование путей API (2026-07-06)

После подтяжки `public-http-openapi.yaml` из GitLab **`f497379`**.

| Тема | Канон GitLab (`docs/` + код) | Было в аналитике (до 2026-07-06) | Решение |
|------|------------------------------|-----------------------------------|---------|
| Претензии | `GET /claims`, `POST /claims` → `/api/claims` | `GET /claim`, `POST /claim` | **Принять GitLab:** обновить ЧТЗ 04, форму претензий; аналитический дрейф снят |
| Поиск (подсказки) | `GET /search` → `/api/search` | — | **Принять GitLab** — suggest по товарам и категориям (`SearchController`, `SearchService`) |
| Поиск (страница результатов) | **`GET /products?q=`** | `GET /search/products` (черновик client) | **Принято W4 (2026-07-06):** страница = `GET /products?q=`; отдельный path не нужен |
| Корзина `CartItem` | `unitPrice`, `lineTotal` = `unit_price × qty` | `packagingMode`, `fullBoxesCount`, `remainderQuantity` (ЧТЗ 01 §4.2.4) | **Блокер реализации** — см. §4 B5 |

---

## 1. Матрица по блокам ЧТЗ и эпикам бэка

| Блок | ЧТЗ / артефакт | Требование MVP (кратко) | GitLab `f497379` | Статус | Пробел / расхождение |
|------|----------------|-------------------------|------------------|--------|----------------------|
| **0** | Инфра | Laravel, PG, Redis, Docker, CI, health | `backend/`, `docker-compose*.yml`, `.gitlab-ci.yml`, `/up` | **Частично** | Прод YC, egress IP, Sentry — не верифицированы по коду |
| **A** | 13, Backend | Версия API, ошибки, correlation id | `Constant::API_PREFIX`, exception render для API | **Частично** | Явный `Correlation-Id` middleware не проверен |
| **A** | 05, 07 | Auth Sanctum: login/register/reset/me | `AuthController`, `auth:sanctum`, `statefulApi()` | **Готово** | Активация после контрагента из 1С — `checkCounterpartyIsNeeded` |
| **A** | 07 | RBAC: директор / закупщик / бухгалтер | `UserRole`, `UserPolicy` (только users) | **Частично** | Нет gates на заказы/документы/корзину по ролям (ЧТЗ 07 §4.6) |
| **A** | — | `GET /csrf-cookie` | Не в `api.php`; Sanctum stateful | **Частично** | В спеке есть путь; уточнить с фронтом (cookie CSRF) |
| **06** | 06 | Категории, товары, карточка | `CategoryController`, `ProductController` | **Готово** | Персональная номенклатура: фильтр `counterparty_guid` |
| **06** | 06 §4.2.0 | `GET /products/filters`, `attr`/`attrRange` | `ProductController::filters`, `ProductsListFilter` | **Готово** | `filters` без `categorySlug` → пустой список (by design) |
| **06** | 06 | Цены, скидки, коробка | `ProductPrice`, импорт `sync.prices` | **Частично** | Отображение mixed qty — зона корзины/API (§4 B5) |
| **06** | 12 | Баннеры, акции, новости, страницы | API read + Filament CRUD | **Готово** | |
| **06** | 12 | `GET /settings` | `SettingController`, `SettingsRegistry` | **Готово** | |
| **01** | 01 | Корзина | `CartController` | **Частично** | `CartItemResource`: `lineTotal = unit_price × qty`; нет полей упаковки |
| **01** | 01 | Оформление заказа | `OrderController::store`, `OrderService` | **Частично** | Создание на платформе; передача в 1С — заглушка |
| **01** | 01 | Заказ из файла | — | **Post-MVP** | ЧТЗ 01 |
| **08** | 08 | История заказов, карточка, repeat | `OrderController` index/view/repeat | **Готово** | 6 статусов в `OrderStatus` |
| **08** | 08 | `integrationSyncState` / сбой синка | `OrderSyncStatus` в модели | **Частично** | **Не отдаётся** в `OrderListItemResource` / OpenAPI |
| **08** | 08 | Delivery-блок | `delivery_type`, `delivery_info` | **Частично** | Inbound-обновление из 1С — **нет** |
| **08** | 08 | Поиск по списку заказов | `?search=` в `OrderController::index` | **Частично** | В public-http для заказов search не описан |
| **02** | 02 | Документы в ЛК | `Document` model + migration | **Частично** | Нет API, нет `get_documents` |
| **03** | 03 | Данные доставки / водитель из 1С | Поля в заказе | **Частично** | Нет inbound-обновления |
| **04** | 04 | Претензии | `ClaimController` → `/api/claims` | **Готово** | OpenAPI `/claims` = код; ЧТЗ 04 обновлён 2026-07-06 |
| **01** | 01 | Нестандартная заявка | Только `Notification` классы | **Нет** | Нет API сохранения заявки |
| **05** | 05 | Регистрация «Стать клиентом» | `register`, `SendRegistrationRequestJob` | **Заглушка** | Job: `// todo real send` |
| **05** | 07 | Управление пользователями ЛК | `UserController` store/patch | **Частично** | Нет `GET /users` list в роутах |
| **07** | 07 | Профиль / контрагент | `me`, `CounterpartyResource` | **Частично** | Нет бонусов в API |
| **09** | 09 | Inbound `POST /exchange` | `ExchangeController`, 8 handlers | **Частично** | Ответ `202` текст `OK`; **нет HMAC/IP** |
| **09** | 09 | События каталога `sync.*` | Все 8 в `WebhookHandlerFactory` | **Готово** | Идемпотентность/inbox — **нет** |
| **09** | 09 | Outbound `post_orders` | `SendOrderJob` | **Заглушка** | Помечает `SYNCED` без вызова 1С |
| **09** | 09 | Inbound статусы заказа / документы | — | **Нет** | События не в factory |
| **10** | 10 | Email + in-app по событиям | `NotificationController`, классы `*Notification` | **Частично** | In-app API есть; email по заказу/claim — не везде |
| **11** | 11 | Поиск: подсказки + страница | `GET /search`, `GET /products?q=` | **Готово** | UI: `perPage=24`; `catalogCode` — post-MVP |
| **14** | 14 | Обучение | `Training/*Controller` | **Готово** | |
| **12** | 12 | Админка | Filament resources | **Готово** | |
| **06** | 06 | Избранное | `FavoriteProductController` | **Готово** | |
| **—** | OpenAPI | `GET /users/{id}` | Только `PATCH /users/{user}` | **Частично** | GET по id в спеке, в роутах нет |

---

## 2. Inbound 1С — детализация

| Событие | ЧТЗ / hooks | Handler + Job | Статус |
|---------|-------------|---------------|--------|
| `sync.product-attributes` | 06, 09 | `SyncProductAttributesHandler` → job | **Готово** |
| `sync.product-types` | 09 | `SyncProductTypesHandler` → job | **Готово** |
| `sync.product-type-characteristics` | 09 | `SyncProductTypeCharacteristicsHandler` → job | **Готово** |
| `sync.products` | 06, 09 | `SyncProductsHandler` → `ImportProductJob` | **Готово** |
| `sync.stocks` | 09 | `SyncStocksHandler` → job | **Готово** |
| `sync.prices` | 06, 09 | `SyncPricesHandler` → job | **Готово** |
| `sync.categories` | 06, 09 | `SyncCategoriesHandler` → job | **Готово** |
| `sync.counterparties` | 05, 09 | `SyncCounterpartiesHandler` → job | **Готово** |
| Заказы / статусы / документы | 08, 09, 02 | — | **Нет** |

**Безопасность exchange (ЧТЗ 09):** HMAC `X-Palizh-Signature`, IP allowlist — **не реализованы** в `ExchangeController`.

---

## 3. Публичный API: спека vs роуты

Канон: **39 path** в `docs/public-http-openapi.yaml` (`f497379`). Реализация: `backend/app/Modules/Api/Routes/api.php` + `Modules/Exchange/Routes/web.php`.

| Path (спека) | Реализация | Статус |
|--------------|------------|--------|
| `/auth/*`, `/me/*` | Да | **Готово** |
| `/csrf-cookie` | Неявно (Sanctum) | **Частично** |
| `/banners`, `/settings`, `/pages/{slug}` | Да | **Готово** |
| `/news`, `/promotions` | Да | **Готово** |
| `/categories`, `/products`, `/products/filters` | Да | **Готово** |
| `/cart`, `/cart/items` | Да | **Частично** — расчёт строки см. B5 |
| `/favorites` | Да | **Готово** |
| `/orders`, `/orders/{id}`, `/orders/{id}/repeat` | Да | **Готово** |
| `/claims` | `/api/claims` | **Готово** |
| `/search` | `/api/search` | **Готово** |
| `GET /products` + `q` | Да (`ProductController`) | **Готово** (страница результатов, W4) |
| `/notifications/*` | `/api/notifications/*` | **Готово** |
| `/training/*` | Да | **Готово** |
| `/users`, `/users/{id}` | POST + PATCH only | **Частично** |
| Документы ЛК | Нет | **Нет** |
| `POST /exchange` | Да (`/exchange`) | **Частично** — без HMAC |

---

## 4. Блокеры и приоритет бэклога

### P0 (критический путь)

| ID | Блокер | Зависимости | Действие |
|----|--------|-------------|----------|
| **B1** | HTTP-клиент 1С: `post_orders`, `get_documents` | 1С публикует сервисы | Реализовать клиент по `1c-http-openapi.yaml` |
| **B2** | Реальная отправка заказа (`SendOrderJob`) | **B1** | Убрать `// todo real send`; не помечать `SYNCED` без ответа 1С |
| **B3** | Inbound статусы заказа + delivery из 1С | Контракт с 1С (#18) | События в `WebhookHandlerFactory`; **параллельно с B1–B2** |
| **B4** | HMAC + allowlist на `/exchange` | №48 | Middleware до приёмки prod |
| **B5** | Расчёт корзины mixed qty (ЧТЗ 01 §4.2.4) | `sync.prices` | `CartItemResource` + приёмка `Приёмка_корзины_vs_счёт_1С.md` |
| **B6** | API документов ЛК + прокси `get_documents` | **B1** | ЧТЗ 02 |

**Рекомендуемая очередь:** **B1 → B2 → B4** (B3 — параллельно с 1С).

### P1 (важно, не блокирует старт интеграции)

| ID | Задача | Комментарий |
|----|--------|-------------|
| W1 | Идемпотентность exchange (inbox) | Ретраи 1С |
| W2 | `integrationSyncState` в API заказа | ЛК и поддержка |
| W3 | Email-триггеры по ЧТЗ 10 | Заказ, claim, training |
| W4 | ~~Согласовать полнотекстовый поиск~~ | **Закрыто** (2026-07-06): страница = `GET /products?q=` |
| W5 | RBAC по разделам ЛК | ЧТЗ 07 §4.6 |

---

## 5. Рекомендуемые следующие шаги

1. **B1–B2:** замкнуть контур заказа с 1С (`post_orders` + обработка ошибок).
2. **B4:** защита `/exchange` (HMAC, IP, JSON-ответ).
3. **B3:** inbound минимум статусов заказа (параллельно с командой 1С).
4. **B5:** mixed qty в корзине + прогон чек-листа приёмки.
5. **B6:** документы ЛК после B1.
6. ~~**W4:** контракт страницы поиска~~ — **закрыто** (ЧТЗ 11, `GET /products?q=`).
7. **Контрактные тесты:** smoke по `public-http-openapi.yaml` + golden files `incoming-hooks.md`.

---

*Документ аналитики; при следующей подтяжке GitLab обновить коммит в шапке и пересмотреть статусы. Не заменяет трекер команды.*
