#!/usr/bin/env ruby
# frozen_string_literal: true

require "time"

REPO = File.expand_path("..", __dir__)
FIXTURE = File.join(REPO, "export", "buildin", "fixtures", "style_test.md")
STYLE_TEST_FILE = File.join(REPO, "export", "buildin", "STYLE_TEST_PAGE")

require File.join(REPO, "tools", "buildin_publish.rb")
load File.join(REPO, "tools", "md_to_buildin_blocks.rb")

abort "Нет фикстуры: #{FIXTURE}" unless File.file?(FIXTURE)

token = load_buildin_token or abort "Нет токена Buildin"
parent_id = load_buildin_target["PAGE_ID"] or abort "Нет PAGE_ID"
markdown = File.read(FIXTURE, encoding: "UTF-8")
intro = buildin_callout_block("Тест конвертации · #{Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")} · #{FIXTURE}")

sequence = [
  { "kind" => "blocks", "blocks" => [intro, divider_block] },
  *md_to_content_sequence(markdown)
]

title = "Тест стилей Markdown"
page = buildin_create_page_title_only(token, parent_id: parent_id, title: title, icon: "🧪")
buildin_publish_content_sequence(token, page["id"], sequence)

meta = {
  "page_id" => page["id"],
  "url" => page["url"],
  "title" => title,
  "published_at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  "fixture" => "export/buildin/fixtures/style_test.md"
}
File.write(STYLE_TEST_FILE, meta.map { |k, v| "#{k}=#{v}" }.join("\n") + "\n", encoding: "UTF-8")

puts "OK: #{page['url']}"
puts "Метаданные: #{STYLE_TEST_FILE}"
