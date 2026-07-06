#!/usr/bin/env ruby
# frozen_string_literal: true

# Обёртка Palizh → глобальный навык buildin-export.
# Из корня репозитория: ruby tools/sync_buildin_export.rb [--incremental] [--section …]

ROOT = File.expand_path("..", __dir__)
SKILL_SYNC = File.expand_path("~/.cursor/skills/buildin-export/scripts/sync_buildin_export.rb")

if File.file?(SKILL_SYNC)
  exec("ruby", SKILL_SYNC, "--project-root", ROOT, *ARGV)
end

warn "Навык buildin-export не найден: #{SKILL_SYNC}"
warn "Установите ~/.cursor/skills/buildin-export/ или запустите скрипт напрямую."
exit 1
