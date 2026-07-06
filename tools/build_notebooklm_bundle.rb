#!/usr/bin/env ruby
# frozen_string_literal: true

# Сборка папки export/notebooklm/bundle/ для загрузки в NotebookLM (≤50 источников).
# Объединяет markdown по блокам; OpenAPI — отдельные YAML без дублирования client+inbound
# (используется openapi_mvp_merged.yaml вместо пары client + 1c_inbound).
#
# Запуск из корня репозитория: ruby tools/build_notebooklm_bundle.rb

REPO = File.expand_path("..", __dir__)
OUT  = File.join(REPO, "export", "notebooklm", "bundle")

def sh_git_rev
  `cd #{REPO.shellescape} && git rev-parse --short HEAD 2>/dev/null`.strip
rescue StandardError
  ""
end

def read_utf8(path)
  File.read(path, encoding: "UTF-8")
end

def merge_markdown(out_path, title, rel_paths)
  missing_strict = []
  File.open(out_path, "w:UTF-8") do |out|
    out.puts "# #{title}"
    out.puts
    out.puts "_Автособорка для NotebookLM. Правки вносить в исходные файлы репозитория, затем пересобрать bundle._"
    out.puts
    rel_paths.compact.each do |rel|
      path = File.join(REPO, rel)
      unless File.file?(path)
        missing_strict << rel
        next
      end
      body = read_utf8(path)
      out.puts
      out.puts
      out.puts "---"
      out.puts
      out.puts "<!-- notebooklm-source: #{rel} -->"
      out.puts
      out.puts body
    end
  end

  raise "Нет файлов: #{missing_strict.join(', ')}" if missing_strict.any?
end

def copy_src(dst_name, rel)
  src = File.join(REPO, rel)
  raise "Нет файла: #{rel}" unless File.file?(src)

  FileUtils.cp(src, File.join(OUT, dst_name))
end

require "fileutils"
require "shellwords"
require "time"

FileUtils.mkdir_p(OUT)
# Важно: bundle используется как рабочий каталог пересборки.
# Чтобы не тащить "хвосты" от прошлых схем нумерации/источников,
# очищаем OUT перед записью.
Dir.chdir(OUT) do
  Dir.glob("*").each { |f| FileUtils.rm_rf(f) }
end

# --- 1. README + план проекта
merge_markdown(
  File.join(OUT, "01_README_и_план_проекта.md"),
  "README и план проекта",
  [
    "README.md",
    "План проекта/План проекта на старте.md"
  ]
)

# --- 2. ЧТЗ (все файлы папки в фиксированном порядке)
chz_order = %w[
  ЧТЗ/Оглавление.md
  ЧТЗ/Глоссарий.md
  ЧТЗ/Матрица_статусов_и_источников.md
  ЧТЗ/Сводка_онбординг_и_идентификаторы.md
  ЧТЗ/01_процесс_оформления_заказа.md
  ЧТЗ/02_документооборот.md
  ЧТЗ/03_доставка.md
  ЧТЗ/04_претензии.md
  ЧТЗ/05_регистрация_онбординг.md
  ЧТЗ/06_витрина_каталог.md
  ЧТЗ/07_ЛК_профиль_компания.md
  ЧТЗ/08_ЛК_заказы_статусы.md
  ЧТЗ/09_интеграция_1С.md
  ЧТЗ/10_уведомления.md
  ЧТЗ/11_поиск.md
  ЧТЗ/12_система_управления.md
  ЧТЗ/13_нефункциональные_требования.md
  ЧТЗ/14_обучение_академия.md
]
merge_markdown(File.join(OUT, "02_ЧТЗ_полный.md"), "ЧТЗ проекта Palizh (полный комплект)", chz_order)

# --- 3. Понимание задачи
merge_markdown(
  File.join(OUT, "03_Понимание_задачи.md"),
  "Понимание задачи",
  ["Понимание задачи/Понимание_задачи.md"]
)

# --- 4. Инфарх
infarch_files =
  Dir.chdir(REPO) do
    Dir.glob("Инфарх/*.md").sort.reject do |rel|
      bn = File.basename(rel)
      down = bn.downcase
      bn.start_with?("План_оценки_") ||
        down.include?("черновик") ||
        down.include?("draft") ||
        down.include?("tmp")
    end
  end

merge_markdown(
  File.join(OUT, "04_Инфарх.md"),
  "Информационная архитектура и границы",
  infarch_files
)

# --- 5. USCases и роли
uscases_files =
  Dir.chdir(REPO) do
    base = Dir.glob("uscases/**/*.md").sort
    prioritised = %w[
      uscases/README.md
      uscases/00_матрица_ролей_и_зон_ответственности.md
      uscases/01_сквозные_mvp_сценарии.md
      uscases/03_покрытие_инфарха.md
      uscases/сценарии_авторизация_и_регистрация.md
    ]
    rest = base - prioritised
    prioritised.select { |f| File.file?(File.join(REPO, f)) } + rest
  end
merge_markdown(File.join(OUT, "05_USCases_и_роли.md"), "USCases, роли и потоки дизайна", uscases_files)

# --- 6. Техническая часть: архитектура, стек, NFR, инфраструктура (без %w — в пути есть пробел)
TECH = "Техническая часть"
tech_arch = [
  "#{TECH}/Архитектура_платформы.md",
  "#{TECH}/Backend_архитектура.md",
  "#{TECH}/Backend_план_работ_MVP.md",
  "#{TECH}/Frontend_архитектура.md",
  "#{TECH}/Техстек_общий.md",
  "#{TECH}/Нефункциональные_требования.md",
  "#{TECH}/Инфраструктура_и_CI-CD.md",
  "#{TECH}/Наблюдаемость_и_логи.md",
  "#{TECH}/Мобильное_приложение_подход.md",
  "#{TECH}/admin_role_and_routing_matrix.md"
]
merge_markdown(
  File.join(OUT, "06_Техническая_часть_архитектура.md"),
  "Техническая часть: архитектура, стек, NFR, инфраструктура",
  tech_arch
)

# --- 7. Интеграция 1С, контракты, задания разработчикам (без OpenAPI-yaml)
tech_1c = [
  "#{TECH}/Интеграция_1С.md",
  "#{TECH}/Модель_данных_каталог_1С_обмен.md",
  "#{TECH}/1C_API_контракт_и_этапы.md",
  "#{TECH}/Задание_1С_разработчику.md",
  "#{TECH}/Маппинг_API_1С.md",
  "#{TECH}/Принятые_решения_API_интеграция_1С.md",
  "#{TECH}/1С_contract_matrix.md",
  "#{TECH}/order_lifecycle_contract.md",
  "#{TECH}/document_delivery_contract.md",
  "#{TECH}/Email_уведомления_MVP_регламент_и_переменные.md",
  "#{TECH}/Задание_разработчику_админка_MVP.md",
  "#{TECH}/Форма_претензии_UI_API.md"
]
merge_markdown(
  File.join(OUT, "07_Техническая_часть_интеграция_1С_и_контракты.md"),
  "Техническая часть: интеграция 1С и контракты данных",
  tech_1c
)

# --- 8. OpenAPI: только поясняющие MD (YAML отдельными источниками)
openapi_md = [
  "#{TECH}/OpenAPI_индекс.md",
  "#{TECH}/openapi_mvp_auth_onboarding.md",
  "#{TECH}/openapi_mvp_catalog_product.md",
  "#{TECH}/openapi_mvp_cart_checkout_orders.md",
  "#{TECH}/openapi_mvp_integration_1c.md"
]
merge_markdown(
  File.join(OUT, "08_OpenAPI_комментарии_и_индекс.md"),
  "OpenAPI: индекс и пояснения к спецификациям MVP",
  openapi_md
)

# --- 9–12. YAML без дублирования: merged вместо пары openapi_client + openapi_1c_inbound
yaml_sources = [
  ["09_openapi_mvp_merged.yaml", "#{TECH}/openapi_mvp_merged.yaml"],
  ["10_public_http_openapi.yaml", "#{TECH}/public-http-openapi.yaml"],
  ["11_1c_http_openapi.yaml", "#{TECH}/1c-http-openapi.yaml"],
  ["12_openapi_post_mvp.yaml", "#{TECH}/openapi_mvp_post_mvp.yaml"]
]
yaml_sources.each { |dst, rel| copy_src(dst, rel) }

# --- Те же 09–12 в Markdown для NotebookLM (тело спецификации в fenced ```yaml)
openapi_md_specs = [
  ["09_openapi_mvp_merged.yaml", "09_openapi_mvp_merged.md", "OpenAPI MVP merged (клиент + 1С inbound)"],
  ["10_public_http_openapi.yaml", "10_public_http_openapi.md", "Публичный HTTP API (public-http)"],
  ["11_1c_http_openapi.yaml", "11_1c_http_openapi.md", "Платформа → публикации 1С (1c-http)"],
  ["12_openapi_post_mvp.yaml", "12_openapi_post_mvp.md", "OpenAPI post-MVP"]
]
openapi_md_specs.each do |yname, mname, heading|
  ypath = File.join(OUT, yname)
  body = read_utf8(ypath)
  md_path = File.join(OUT, mname)
  File.write(
    md_path,
    "# #{heading}\n\nИсходный YAML: **`#{yname}`**.\n\n```yaml\n#{body.rstrip.chomp("\n")}\n```\n",
    encoding: "UTF-8"
  )
end

# --- 13. Интервью: саммари, реестры, сводные материалы (без Транскрайб/, без архива интервью)
interview_summaries = Dir.chdir(REPO) { Dir.glob("Интервью и встречи/Саммари/*.md").sort }
interview_misc = [
  "Интервью и встречи/Информация на старте.md",
  "Интервью и встречи/Карта_заинтересованных_сторон.md",
  "Интервью и встречи/Реестр_открытых_вопросов.md",
  "Интервью и встречи/Реестр_документов_для_проектирования.md",
  "Интервью и встречи/Вопросы_клиенту_по_процессу_заказа.md",
  "Интервью и встречи/2026-03-25_обучение_аудит_процесса_и_сценарии_уточнений.md",
  "Интервью и встречи/2026-03-30_аудит_документации_итоги.md",
  "Интервью и встречи/2026-03-30_аудит_документации_пакет_правок.md"
]

interview_block = []
interview_block += interview_summaries
interview_block += interview_misc

merge_markdown(
  File.join(OUT, "13_Интервью_саммари_и_реестры.md"),
  "Интервью и встречи: саммари, реестры, ключевые материалы",
  interview_block.compact
)

# --- 14. Входящие (webhooks MD; YAML дублирует 11 — не копируем)
merge_markdown(
  File.join(OUT, "14_Входящие_webhooks.md"),
  "Входящие webhook / обмен от 1С",
  ["входящие/incoming-hooks.md"]
)

# Manifest
manifest = File.join(REPO, "export", "notebooklm", "MANIFEST.md")
File.open(manifest, "w:UTF-8") do |m|
  m.puts "# NotebookLM bundle — манифест"
  m.puts
  m.puts "- **Дата сборки:** #{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} (UTC)"
  m.puts "- **Коммит (короткий):** #{sh_git_rev.empty? ? '— (не git)' : sh_git_rev}"
  md_count = Dir.chdir(OUT) { Dir.glob("*.md").length }
  m.puts "- **Число источников для ноутбука:** #{md_count} файлов `*.md` в `bundle/`"
  m.puts
  m.puts "## Исключено намеренно"
  m.puts
  m.puts "- `архив/` и `Аудит_документации_*.md` — исторические снимки и отчёты аудита; в NotebookLM не включаются."
  m.puts "- `Интервью …/Транскрайб/` — сырые расшифровки; в корпусе только саммари."
  m.puts "- `openapi_client_mvp.yaml` и `openapi_1c_inbound_mvp.yaml` — входят объединённые в **`09_openapi_mvp_merged.yaml`**."
  m.puts "- `входящие/1c-http-openapi.yaml` — дубликат канонического `Техническая часть/1c-http-openapi.yaml` (**`11_1c_http_openapi.yaml`**)."
  m.puts "- `Понимание задачи/архив/` и прочие архивные снимки понимания."
  m.puts "- Временные рабочие файлы (например `Инфарх/План_оценки_*.md`, `*черновик*`, `*draft*`, `*tmp*`) — не включаются в NotebookLM."
  m.puts "- `.cursor/`, образцы документов, записи интервью."
  m.puts "- **`bundle/*.yaml`** (09–12) — техническая копия OpenAPI для merge/валидаторов и т.п.; **`bundle/*.md`** для тех же ключей включают тот же контент как Markdown (**`notebooklm`/NotebookLM загружает именно их**)."
  m.puts
  m.puts "## Файлы в bundle/"
  m.puts
  Dir.chdir(OUT) { Dir.glob("*").sort.each { |f| m.puts "- `#{f}`" } }
end

puts "OK: собран каталог #{OUT}"
puts "Манифест: #{manifest}"
