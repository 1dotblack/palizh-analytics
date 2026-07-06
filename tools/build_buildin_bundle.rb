#!/usr/bin/env ruby
# frozen_string_literal: true

# Сборка bundle для Buildin из export/buildin/SOURCES.json
# Делегирует в глобальный навык buildin-export.

ROOT = File.expand_path("..", __dir__)
SKILL = File.expand_path("~/.cursor/skills/buildin-export/scripts/build_buildin_bundle.rb")

if File.file?(SKILL)
  exec("ruby", SKILL, "--project-root", ROOT, *ARGV)
end

abort "Навык buildin-export не найден: #{SKILL}"
