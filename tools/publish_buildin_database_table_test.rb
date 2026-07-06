#!/usr/bin/env ruby
# frozen_string_literal: true

require "time"

REPO = File.expand_path("..", __dir__)
FIXTURE = File.join(REPO, "export", "buildin", "fixtures", "table_test.md")
META_FILE = File.join(REPO, "export", "buildin", "DATABASE_TABLE_TEST_PAGE")

require File.join(REPO, "tools", "buildin_publish.rb")
load File.join(REPO, "tools", "md_to_buildin_blocks.rb")

abort "Нет фикстуры: #{FIXTURE}" unless File.file?(FIXTURE)

token = load_buildin_token or abort "Нет токена Buildin"
parent_id = load_buildin_target["PAGE_ID"] or abort "Нет PAGE_ID"
markdown = File.read(FIXTURE, encoding: "UTF-8")

sequence = [
  {
    "kind" => "blocks",
    "blocks" => [
      paragraph_block("GFM-таблица из fixture → inline database (пайплайн выгрузки).")
    ]
  },
  *md_to_content_sequence(markdown)
]

title = "Тест таблицы (database)"
page = buildin_create_page_title_only(token, parent_id: parent_id, title: title, icon: "🧪")
buildin_publish_content_sequence(token, page["id"], sequence)

db_id = nil
query_count = 0
BuildinApi.list_block_children(token, page["id"]).each do |block|
  next unless block["type"] == "child_database"

  db_id = block.dig("child_database", "database_id") || block["id"]
end
if db_id
  query = BuildinApi.request!(token, :post, "/databases/#{db_id}/query", { "page_size" => 50 })
  query_count = query["results"]&.length.to_i
end

meta = {
  "page_id" => page["id"],
  "url" => page["url"],
  "database_id" => db_id,
  "rows" => query_count.to_s,
  "fixture" => "export/buildin/fixtures/table_test.md",
  "published_at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
}
File.write(META_FILE, meta.map { |k, v| "#{k}=#{v}" }.join("\n") + "\n", encoding: "UTF-8")

puts "OK: #{page['url']}"
puts "Database: #{db_id}, строк: #{query_count}"
puts "Метаданные: #{META_FILE}"
