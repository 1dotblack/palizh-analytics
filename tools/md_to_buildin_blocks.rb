#!/usr/bin/env ruby
# frozen_string_literal: true

# Конвертация Markdown → JSON-массив блоков Buildin API (Notion-подобная схема).
# Используется агентом выгрузки в Buildin и скриптом sync_buildin_export.rb.
#
# Запуск:
#   ruby tools/md_to_buildin_blocks.rb path/to/doc.md
#   ruby tools/md_to_buildin_blocks.rb path/to/doc.md --out blocks.json
#   ruby tools/md_to_buildin_blocks.rb path/to/doc.md --max-chunk 80

require "json"
require "optparse"

MAX_TEXT = 2000
DEFAULT_CHUNK = 100

def default_annotations(overrides = {})
  {
    "bold" => false,
    "italic" => false,
    "strikethrough" => false,
    "underline" => false,
    "code" => false,
    "color" => "default"
  }.merge(overrides)
end

def text_rt(content, annotations: {}, link: nil)
  ann = default_annotations(annotations)
  link_obj = link ? { "url" => link } : nil
  {
    "type" => "text",
    "text" => { "content" => content, "link" => link_obj },
    "annotations" => ann,
    "plain_text" => content,
    "href" => link
  }
end

def split_long_text(text, max_len = MAX_TEXT)
  return [text] if text.length <= max_len

  parts = []
  rest = text
  while rest.length > max_len
    cut = rest.rindex(" ", max_len) || max_len
    parts << rest[0...cut]
    rest = rest[cut..].lstrip
  end
  parts << rest unless rest.empty?
  parts
end

def parse_inline(text)
  segments = []
  i = 0
  while i < text.length
    if text[i..]&.start_with?("`")
      j = text.index("`", i + 1)
      if j
        inner = text[(i + 1)...j]
        segments << text_rt(inner, annotations: { "code" => true })
        i = j + 1
        next
      end
    end

  m = text[i..]&.match(/\A\[(?<label>[^\]]+)\]\((?<url>[^)]+)\)/)
    if m
      segments << text_rt(m[:label], link: m[:url])
      i += m[0].length
      next
    end

    m = text[i..]&.match(/\A\*\*(?<b>.+?)\*\*/)
    if m
      segments << text_rt(m[:b], annotations: { "bold" => true })
      i += m[0].length
      next
    end

    m = text[i..]&.match(/\A\*(?<it>.+?)\*/)
    if m
      segments << text_rt(m[:it], annotations: { "italic" => true })
      i += m[0].length
      next
    end

    next_special = text[i..].index(/[\[`*]/) || text.length
    plain = text[i...(i + next_special)]
    if plain.empty?
      i += 1
      next
    end
    segments << text_rt(plain)
    i += plain.length
  end

  segments.empty? ? [text_rt("")] : segments
end

def paragraph_block(text)
  rich = parse_inline(text.strip)
  {
    "object" => "block",
    "type" => "paragraph",
    "paragraph" => { "rich_text" => rich }
  }
end

def heading_block(level, text)
  key = "heading_#{level}"
  {
    "object" => "block",
    "type" => key,
    key => { "rich_text" => parse_inline(text.strip) }
  }
end

def list_item_block(type, text)
  {
    "object" => "block",
    "type" => type,
    type => { "rich_text" => parse_inline(text.strip) }
  }
end

def code_block(lang, body)
  chunks = split_long_text(body)
  chunks.map do |chunk|
    {
      "object" => "block",
      "type" => "code",
      "code" => {
        "rich_text" => [text_rt(chunk)],
        "language" => lang.to_s.empty? ? "plain text" : lang
      }
    }
  end
end

def quote_block(text)
  {
    "object" => "block",
    "type" => "quote",
    "quote" => { "rich_text" => parse_inline(text.strip) }
  }
end

def divider_block
  { "object" => "block", "type" => "divider", "divider" => {} }
end

def table_line?(line)
  s = line.strip
  s.start_with?("|") && s.end_with?("|") && s.length > 1
end

def table_separator?(line)
  return false unless table_line?(line)

  line.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|").all? do |cell|
    cell.strip.match?(/\A:?-{3,}:?\z/)
  end
end

def parse_cells(line)
  line.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|").map { |c| parse_inline(c.strip) }
end

def cell_plain(cells)
  cells.map { |seg| seg["plain_text"] }.join
end

def table_row_block(cells)
  {
    "object" => "block",
    "type" => "table_row",
    "table_row" => { "cells" => cells }
  }
end

def normalize_row_cells(cells, width)
  row = cells.dup
  row << [text_rt("")] while row.length < width
  row[0, width]
end

def table_block_from_rows(raw_rows)
  return [] if raw_rows.empty?

  body_lines = raw_rows.dup
  body_lines.delete_at(1) if body_lines.length > 1 && table_separator?(body_lines[1])

  rows = body_lines.map { |line| parse_cells(line) }
  width = rows.map(&:length).max
  width = 1 if width.nil? || width.zero?

  [{
    "object" => "block",
    "type" => "table",
    "table" => {
      "table_width" => width,
      "has_column_header" => false,
      "has_row_header" => false
    },
    "children" => rows.map { |cells| table_row_block(normalize_row_cells(cells, width)) }
  }]
end

def steps_table_blocks(raw_rows)
  return table_block_from_rows(raw_rows) unless raw_rows.length >= 2 && table_separator?(raw_rows[1])

  headers = parse_cells(raw_rows[0]).map { |rt| cell_plain(rt) }
  return table_block_from_rows(raw_rows) unless headers.first&.strip == "№"

  blocks = []
  raw_rows[2..].each do |row_line|
    texts = row_line.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|").map(&:strip)
    next if texts.all?(&:empty?)

    num = texts[0]
    title = texts[1].to_s
    blocks << heading_block(3, "#{num} — #{title}")
    (2...texts.length).each do |ci|
      val = texts[ci].to_s.strip
      next if val.empty?

      label = headers[ci].to_s.strip
      blocks << list_item_block("bulleted_list_item", "#{label}: #{val}")
    end
  end
  blocks
end

def table_markdown_block(raw_lines)
  body = raw_lines.join("\n").strip
  code_block("markdown", body)
end

def table_blocks_from_markdown(raw_rows)
  mode = ENV.fetch("BUILDIN_TABLE_MODE", "database")
  case mode
  when "database"
    []
  when "native"
    table_block_from_rows(raw_rows)
  when "steps"
    if raw_rows.length >= 2 && table_separator?(raw_rows[1]) &&
       parse_cells(raw_rows[0]).map { |rt| cell_plain(rt) }.first&.strip == "№"
      steps_table_blocks(raw_rows)
    else
      table_block_from_rows(raw_rows)
    end
  when "markdown"
    table_markdown_block(raw_rows)
  else
    table_block_from_rows(raw_rows)
  end
end

def database_item_from_raw_rows(raw_rows, table_index: 0)
  require_relative "md_table_database"
  parsed = MdTableDatabase.parse_gfm_table_raw_rows(raw_rows)
  return nil unless parsed

  headers, rows = parsed
  {
    "kind" => "database",
    "title" => MdTableDatabase.database_title(headers, table_index),
    "headers" => headers,
    "rows" => rows
  }
end

def md_to_content_sequence(markdown)
  lines = markdown.gsub("\r\n", "\n").split("\n")
  items = []
  pending_blocks = []
  table_index = 0
  i = 0

  flush_blocks = lambda do
    next if pending_blocks.empty?

    items << { "kind" => "blocks", "blocks" => pending_blocks.dup }
    pending_blocks.clear
  end

  while i < lines.length
    line = lines[i]

    if line.strip.empty?
      i += 1
      next
    end

    if line.strip.match?(%r{\A<!--.*-->\z})
      i += 1
      next
    end

    if line.start_with?("```")
      lang = line[3..].strip
      i += 1
      body_lines = []
      while i < lines.length && !lines[i].start_with?("```")
        body_lines << lines[i]
        i += 1
      end
      i += 1 if i < lines.length
      pending_blocks.concat(code_block(lang, body_lines.join("\n")))
      next
    end

    if line =~ /^---+\s*$/
      pending_blocks << divider_block
      i += 1
      next
    end

    if line =~ /^(#+)\s+(.+)$/
      level = [Regexp.last_match(1).length, 3].min
      pending_blocks << heading_block(level, Regexp.last_match(2))
      i += 1
      next
    end

    if line =~ /^>\s?(.*)$/
      pending_blocks << quote_block(Regexp.last_match(1))
      i += 1
      next
    end

    if table_line?(line)
      raw_rows, i = parse_table_section(lines, i)
      if ENV.fetch("BUILDIN_TABLE_MODE", "database") == "database"
        flush_blocks.call
        db_item = database_item_from_raw_rows(raw_rows, table_index: table_index)
        items << db_item if db_item
        table_index += 1
      else
        pending_blocks.concat(table_blocks_from_markdown(raw_rows))
      end
      next
    end

    if line =~ /^[-*+]\s+(.+)$/
      pending_blocks << list_item_block("bulleted_list_item", Regexp.last_match(1))
      i += 1
      next
    end

    if line =~ /^\d+\.\s+(.+)$/
      pending_blocks << list_item_block("numbered_list_item", Regexp.last_match(1))
      i += 1
      next
    end

    para = [line]
    i += 1
    while i < lines.length && !lines[i].strip.empty? && !lines[i].match?(%r{^(#+\s|[-*+]\s|\d+\.\s|>|```|---|\|)})
      para << lines[i]
      i += 1
    end
    text = para.join("\n")
    split_long_text(text).each { |part| pending_blocks << paragraph_block(part) }
  end

  flush_blocks.call
  items
end

def parse_table_section(lines, start_i)
  rows = []
  i = start_i
  while i < lines.length && table_line?(lines[i])
    rows << lines[i]
    i += 1
  end
  [rows, i]
end

def callout_block(text, emoji: "ℹ️")
  {
    "object" => "block",
    "type" => "callout",
    "callout" => {
      "rich_text" => parse_inline(text.strip),
      "icon" => { "type" => "emoji", "emoji" => emoji }
    }
  }
end

def md_to_blocks(markdown)
  lines = markdown.gsub("\r\n", "\n").split("\n")
  blocks = []
  i = 0

  while i < lines.length
    line = lines[i]

    if line.strip.empty?
      i += 1
      next
    end

    if line.strip.match?(%r{\A<!--.*-->\z})
      i += 1
      next
    end

    if line.start_with?("```")
      lang = line[3..].strip
      i += 1
      body_lines = []
      while i < lines.length && !lines[i].start_with?("```")
        body_lines << lines[i]
        i += 1
      end
      i += 1 if i < lines.length
      blocks.concat(code_block(lang, body_lines.join("\n")))
      next
    end

    if line =~ /^---+\s*$/
      blocks << divider_block
      i += 1
      next
    end

    if line =~ /^(#+)\s+(.+)$/
      level = [Regexp.last_match(1).length, 3].min
      blocks << heading_block(level, Regexp.last_match(2))
      i += 1
      next
    end

    if line =~ /^>\s?(.*)$/
      blocks << quote_block(Regexp.last_match(1))
      i += 1
      next
    end

    if table_line?(line)
      raw_rows, i = parse_table_section(lines, i)
      blocks.concat(table_blocks_from_markdown(raw_rows))
      next
    end

    if line =~ /^[-*+]\s+(.+)$/
      blocks << list_item_block("bulleted_list_item", Regexp.last_match(1))
      i += 1
      next
    end

    if line =~ /^\d+\.\s+(.+)$/
      blocks << list_item_block("numbered_list_item", Regexp.last_match(1))
      i += 1
      next
    end

    para = [line]
    i += 1
    while i < lines.length && !lines[i].strip.empty? && !lines[i].match?(%r{^(#+\s|[-*+]\s|\d+\.\s|>|```|---|\|)})
      para << lines[i]
      i += 1
    end
    text = para.join("\n")
    split_long_text(text).each { |part| blocks << paragraph_block(part) }
  end

  blocks
end

def chunk_blocks(blocks, size)
  blocks.each_slice(size).to_a
end

if __FILE__ == $PROGRAM_NAME
  options = { chunk: DEFAULT_CHUNK, out: nil }
  OptionParser.new do |o|
  o.on("--out PATH", "Записать JSON в файл") { |v| options[:out] = v }
  o.on("--max-chunk N", Integer, "Размер пачки блоков (по умолчанию #{DEFAULT_CHUNK})") { |v| options[:chunk] = v }
end.parse!

path = ARGV[0]
abort "Укажите путь к .md: ruby tools/md_to_buildin_blocks.rb FILE.md" unless path
abort "Нет файла: #{path}" unless File.file?(path)

markdown = File.read(path, encoding: "UTF-8")
sequence = md_to_content_sequence(markdown)
blocks = sequence.flat_map { |item| item["kind"] == "blocks" ? item["blocks"] : [] }
databases = sequence.count { |item| item["kind"] == "database" }
payload = {
  "source" => path,
  "block_count" => blocks.length,
  "database_count" => databases,
  "sequence" => sequence,
  "chunks" => chunk_blocks(blocks, options[:chunk])
}

json = JSON.pretty_generate(payload)
if options[:out]
  File.write(options[:out], json, encoding: "UTF-8")
  warn "OK: #{blocks.length} блоков → #{options[:out]}"
  else
    puts json
  end
end
