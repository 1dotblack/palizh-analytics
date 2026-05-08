#!/usr/bin/env ruby
# frozen_string_literal: true

# Разделяет объединённый OpenAPI (архив/merge) на клиент и 1С inbound — вспомогательно.
# Запуск: ruby tools/split_openapi_client_and_1c.rb [путь_к_объединённому.yaml]
# По умолчанию источник: архив/openapi_mvp_monolith_2026-04-17.yaml
# Канон для правок: openapi_client_mvp.yaml и openapi_1c_inbound_mvp.yaml; см. OpenAPI_индекс.md

require 'yaml'
require 'set'

ROOT = File.expand_path('..', __dir__)
ARCH = File.join(File.expand_path('../..', __dir__), 'архив', 'openapi_mvp_monolith_2026-04-17.yaml')
MERGED = File.join(ROOT, 'openapi_mvp_merged.yaml')
SRC = if ARGV[0] && File.file?(ARGV[0])
  ARGV[0]
elsif File.file?(MERGED)
  MERGED
elsif File.file?(ARCH)
  ARCH
end
OUT_CLIENT = File.join(ROOT, 'openapi_client_mvp.yaml')
OUT_1C_IN = File.join(ROOT, 'openapi_1c_inbound_mvp.yaml')

def deep_refs(obj, acc = [])
  case obj
  when Hash
    r = obj['$ref']
    acc << r if r.is_a?(String) && r.start_with?('#/components/')
    obj.each_value { |v| deep_refs(v, acc) }
  when Array
    obj.each { |v| deep_refs(v, acc) }
  end
  acc
end

def collect_schema_closure(schemas, root_refs)
  needed = Set.new
  queue = root_refs.dup
  until queue.empty?
    ref = queue.shift
    next if needed.include?(ref)
    needed.add(ref)
    next unless ref.start_with?('#/components/schemas/')
    name = ref.sub('#/components/schemas/', '')
    sch = schemas[name]
    next unless sch
    deep_refs(sch).each do |r|
      queue << r unless needed.include?(r)
    end
  end
  needed
end

def security_from_paths(paths_hash)
  s = Set.new
  paths_hash.each_value do |path_item|
    path_item.each_value do |op|
      next unless op.is_a?(Hash)
      (op['security'] || []).each do |req|
        req.each_key { |k| s.add(k) }
      end
    end
  end
  s
end

if SRC.nil? || !File.file?(SRC)
  warn "Нет исходного YAML. Ожидается `openapi_mvp_merged.yaml`, архив или путь: ruby tools/split_openapi_client_and_1c.rb <файл>"
  exit 1
end
puts "Источник: #{SRC}"

doc = YAML.load_file(SRC)
paths = doc['paths'] || {}
client_paths = {}
int_paths = {}
paths.each do |k, v|
  if k.start_with?('/integrations/1c')
    int_paths[k] = v
  else
    client_paths[k] = v
  end
end

comp = doc['components'] || {}
schemas = comp['schemas'] || {}

c_root = deep_refs(client_paths)
i_root = deep_refs(int_paths)
c_schema_refs = collect_schema_closure(schemas, c_root)
i_schema_refs = collect_schema_closure(schemas, i_root)

c_names = c_schema_refs.select { |r| r.start_with?('#/components/schemas/') }
                       .map { |r| r.sub('#/components/schemas/', '') }
i_names = i_schema_refs.select { |r| r.start_with?('#/components/schemas/') }
                       .map { |r| r.sub('#/components/schemas/', '') }

c_sec = security_from_paths(client_paths)
i_sec = security_from_paths(int_paths)

c_schemes = (comp['securitySchemes'] || {}).slice(*c_sec.to_a)
i_schemes = (comp['securitySchemes'] || {}).slice(*i_sec.to_a)

tags = doc['tags'] || []
c_tags = tags.reject { |t| t['name'] == 'Integration 1C' }
i_tags = tags.select { |t| t['name'] == 'Integration 1C' }

c_info = (doc['info'] || {}).merge(
  'title' => 'Palizh — API витрины и ЛК (клиент)',
  'summary' => 'Контракт клиент (браузер/приложение) ↔ бэкенд: JWT, каталог, корзина, заказы, документы',
  'description' => <<~DESC
    Спецификация **публичного** HTTP API для фронтенда и мобильного клиента (витрина, личный кабинет B2B).

    **Не входит в этот файл:** входящие вызовы **1С → платформа** — `openapi_1c_inbound_mvp.yaml`. Исходящие **платформа → 1С** — `1c-http-openapi.yaml`.
  DESC
)

i_info = (doc['info'] || {}).merge(
  'title' => 'Palizh — входящая интеграция 1С → платформа',
  'summary' => 'Server-to-server: HMAC, только пути /integrations/1c/*',
  'description' => <<~DESC
    Спецификация **входящих** на бэкенд вызовов **от 1С** (без UI). Подпись HMAC, allowlist IP — см. `Интеграция_1С.md` §4.3–4.4.

    **Публичный** API витрины/ЛК — `openapi_client_mvp.yaml`. **Исходящие** в HTTP-сервисы 1С — `1c-http-openapi.yaml`.
  DESC
)

client_doc = {
  'openapi' => doc['openapi'],
  'info' => c_info,
  'servers' => doc['servers'],
  'tags' => c_tags,
  'paths' => client_paths,
  'components' => { 'securitySchemes' => c_schemes, 'schemas' => schemas.slice(*c_names) }
}

int_doc = {
  'openapi' => doc['openapi'],
  'info' => i_info,
  'servers' => doc['servers'],
  'tags' => i_tags,
  'paths' => int_paths,
  'components' => { 'securitySchemes' => i_schemes, 'schemas' => schemas.slice(*i_names) }
}

def dump(path, d, head_lines)
  File.write(path, head_lines + d.to_yaml(line_width: 120))
end

H_CLIENT = <<~H
  # Канон: витрина/ЛК ↔ бэкенд. Не смешивать с 1С inbound — см. OpenAPI_индекс.md
  # (пересборка: ruby tools/split_openapi_client_and_1c.rb [источник.yaml])
H
H_1C = <<~H
  # Канон: 1С → платформа (/integrations/1c/*). Публичный API — openapi_client_mvp.yaml
H

dump(OUT_CLIENT, client_doc, H_CLIENT)
dump(OUT_1C_IN, int_doc, H_1C)

puts "OK: #{OUT_CLIENT} (paths: #{client_paths.size}, schemas: #{c_names.size})"
puts "OK: #{OUT_1C_IN} (paths: #{int_paths.size}, schemas: #{i_names.size})"
