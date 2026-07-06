# Ожидает push в GitLab (nutnet/palizh)

Локальная среда не имеет прав на `git push` (HTTPS 403, SSH без ключа).

## Что обновить

Только **`docs/incoming-hooks.md`** — коробка, `unitsPerBox`, три вида цен, скидка к рознице (2026-06-02).

**Не трогать** `docs/public-http-openapi.yaml` из аналитики: в `gitlab/main` ~2291 строк, в аналитике ~1478 — канон на GitLab новее.

## Как применить

1. В репозитории [nutnet/palizh](https://gitlab.com/nutnet/palizh): заменить `docs/incoming-hooks.md` файлом `incoming-hooks.md` из этой папки **или** применить `0001-docs-1-unitsPerBox.patch` на ветку `main`.
2. Merge request с сообщением коммита из патча.

Коммит подготовлен локально: `d14dc54` (клон `/tmp/palizh-gitlab-sync`).
