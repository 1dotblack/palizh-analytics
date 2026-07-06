#!/usr/bin/env ruby
# frozen_string_literal: true

# Тестовая страница с GFM-таблицей в Buildin.
# Запуск из корня: ruby tools/publish_buildin_table_test.rb

require "json"
require "time"

REPO = File.expand_path("..", __dir__)
FIXTURE = File.join(REPO, "export", "buildin", "fixtures", "table_test.md")
TARGET_FILE = File.join(REPO, "export", "buildin", "BUILDIN_TARGET")
META_FILE = File.join(REPO, "export", "buildin", "TABLE_TEST_PAGE")
CHUNK_SIZE = 100

require File.join(REPO, "tools", "buildin_api.rb")
load File.join(REPO, "tools", "md_to_buildin_blocks.rb")

def load_parent_id
  vars = {}
  File.readlines(TARGET_FILE, encoding: "UTF-8").each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")

    k, v = line.split("=", 2)
    vars[k] = v
  end
  vars["PAGE_ID"] or abort "Нет PAGE_ID в BUILDIN_TARGET"
end

def title_property(text)
  {
    "title" => {
      "type" => "title",
      "title" => [{
        "type" => "text",
        "text" => { "content" => text, "link" => nil },
        "annotations" => default_annotations,
        "plain_text" => text,
        "href" => nil
      }]
    }
  }
end

def append_blocks(token, page_id, blocks)
  blocks.each_slice(CHUNK_SIZE) do |chunk|
    sleep BuildinApi::SLEEP_SEC
    BuildinApi.request!(token, :patch, "/blocks/#{page_id}/children", { "children" => chunk })
  end
end

abort "Нет фикстуры: #{FIXTURE}" unless File.file?(FIXTURE)

token = BuildinApi.load_token or abort "Нет токена Buildin"
parent_id = load_parent_id
markdown = File.read(FIXTURE, encoding: "UTF-8")
title = "Тест таблицы GFM"

page = BuildinApi.request!(token, :post, "/pages", {
  "parent" => { "page_id" => parent_id },
  "icon" => { "type" => "emoji", "emoji" => "🧪" },
  "properties" => title_property(title)
})
page_id = page["id"]

if BuildinApi.replace_page_markdown(token, page_id, markdown) == :ok
  mode = "markdown_put"
else
  blocks = md_to_blocks(markdown)
  if BuildinApi.page_has_empty_tables?(token, page_id) == false
    # noop
  end
  append_blocks(token, page_id, blocks)
  mode = "blocks"
  if BuildinApi.page_has_empty_tables?(token, page_id)
    append_blocks(token, page_id, [
      callout_block(
        "Сетка таблицы создана, но API не заполнил ячейки. " \
        "Для эталонного вида: откройте страницу → вставьте содержимое `export/buildin/fixtures/table_test.md` в редактор.",
        emoji: "ℹ️"
      )
    ])
    mode = "blocks_empty_cells"
  end
end

meta = {
  "page_id" => page_id,
  "url" => page["url"],
  "title" => title,
  "mode" => mode,
  "fixture" => "export/buildin/fixtures/table_test.md",
  "published_at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
}
File.write(META_FILE, meta.map { |k, v| "#{k}=#{v}" }.join("\n") + "\n", encoding: "UTF-8")

puts "OK: #{page['url']}"
puts "Режим: #{mode}"
puts "Фикстура: #{FIXTURE}"
puts "Метаданные: #{META_FILE}"
