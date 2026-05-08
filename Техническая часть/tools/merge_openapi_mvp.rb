#!/usr/bin/env ruby
# frozen_string_literal: true

# Собирает объединённый OpenAPI (витрина/ЛК + 1С inbound) из двух файлов-источников.
# Запуск: ruby tools/merge_openapi_mvp.rb

require 'yaml'

ROOT = File.expand_path('..', __dir__)
C = File.join(ROOT, 'openapi_client_mvp.yaml')
I = File.join(ROOT, 'openapi_1c_inbound_mvp.yaml')
OUT = File.join(ROOT, 'openapi_mvp_merged.yaml')

c = YAML.load_file(C)
i = YAML.load_file(I)

c_schemas = c.dig('components', 'schemas') || {}
i_schemas = i.dig('components', 'schemas') || {}
(c_schemas.keys & i_schemas.keys).each do |k|
  if c_schemas[k] != i_schemas[k]
    warn "Расхождение в схеме #{k}; в объединённом спекe останется вариант из клиентского файла (первый merge)."
  end
end

merged_schemas = c_schemas.merge(i_schemas)

sec = (c.dig('components', 'securitySchemes') || {}).merge(i.dig('components', 'securitySchemes') || {})

merged = c.dup
merged['info'] = {
  'title' => 'Palizh MVP API — объединённый (клиент + 1С inbound)',
  'version' => c.dig('info', 'version') || i.dig('info', 'version') || '0.1.0',
  'summary' => 'Один файл для демо/лLint: = openapi_client_mvp.yaml + openapi_1c_inbound_mvp.yaml',
  'description' => <<~DESC
    **Собрано** из `openapi_client_mvp.yaml` и `openapi_1c_inbound_mvp.yaml` (см. `OpenAPI_индекс.md`).
    Канон для правок — **два** отдельных файла; этот — для инструментов, которым нужен один bundle.
  DESC
}
merged['tags'] = (c['tags'] || []) + (i['tags'] || [])
merged['paths'] = (c['paths'] || {}).merge(i['paths'] || {})
merged['components'] = { 'securitySchemes' => sec, 'schemas' => merged_schemas }

File.write(OUT, <<~HEAD + merged.to_yaml(line_width: 120))
  # Сгенерировано: ruby tools/merge_openapi_mvp.rb — не править вручную; правьте openapi_client_mvp / openapi_1c_inbound
HEAD

puts "OK: #{OUT} (paths: #{merged['paths'].size}, schemas: #{merged_schemas.size})"
