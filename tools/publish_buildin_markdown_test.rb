#!/usr/bin/env ruby
# frozen_string_literal: true

# Проверка публикации Markdown с таблицами в Buildin.
# Сравнивает PUT markdown (когда появится) и blocks API.
#
# Запуск из корня:
#   ruby tools/publish_buildin_markdown_test.rb
#   ruby tools/publish_buildin_markdown_test.rb path/to/doc.md

require "json"
require "time"

REPO = File.expand_path("..", __dir__)
DEFAULT_MD = File.join(REPO, "Аудит_документации_2026-06-02.md")
TARGET_FILE = File.join(REPO, "export", "buildin", "BUILDIN_TARGET")
RESULT_FILE = File.join(REPO, "export", "buildin", "MARKDOWN_TABLE_TEST")

require_relative "buildin_api"
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

md_path = ARGV[0] || DEFAULT_MD
abort "Нет файла: #{md_path}" unless File.file?(md_path)

token = BuildinApi.load_token or abort "Нет токена Buildin"
parent_id = load_parent_id
markdown = File.read(md_path, encoding: "UTF-8")
title = "_md_table_test_#{File.basename(md_path, ".md")}"

page = BuildinApi.request!(
  token, :post, "/pages",
  {
    "parent" => { "page_id" => parent_id },
    "icon" => { "type" => "emoji", "emoji" => "🧪" },
    "properties" => title_property(title)
  }
)
page_id = page["id"]

puts "Страница: #{page['url']}"
puts

md_status = BuildinApi.put_page_markdown(token, page_id, markdown)
puts "1. PUT /pages/{id}/content/markdown → #{md_status}"

if md_status == :ok
  exported = BuildinApi.get_page_markdown(token, page_id)["markdown"].to_s
  has_table = exported.include?("|")
  puts "   GET markdown содержит таблицу: #{has_table}"
else
  puts "   (ожидаемо: в OpenAPI v2 только GET markdown)"
  puts

  table_block = table_block_from_rows(
    markdown.lines.grep(/\A\|/).first(3)
  ).first
  BuildinApi.request!(token, :patch, "/blocks/#{page_id}/children", {
    "children" => [table_block]
  })
  tbl_id = BuildinApi.list_block_children(token, page_id).find { |b| b["type"] == "table" }["id"]
  empty = BuildinApi.table_block_empty?(token, tbl_id)
  puts "2. blocks API table + table_row → ячейки пустые: #{empty}"
  puts "   Эталон с таблицами: импорт MD в UI (Аудит_документации_2026-06-02)"
end

File.write(
  RESULT_FILE,
  [
    "page_id=#{page_id}",
    "url=#{page['url']}",
    "source=#{md_path}",
    "markdown_put=#{md_status}",
    "tested_at=#{Time.now.utc.iso8601}"
  ].join("\n") + "\n",
  encoding: "UTF-8"
)

puts
puts "Метаданные: #{RESULT_FILE}"
