# frozen_string_literal: true

# GFM-таблица → inline database Buildin API.
# Парсинг inline-разметки — из md_to_buildin_blocks.rb (load перед require).

module MdTableDatabase
  module_function

  def table_mode
    ENV.fetch("BUILDIN_TABLE_MODE", "database")
  end

  def use_database?
    table_mode == "database"
  end

  def parse_gfm_table_raw_rows(raw_rows)
    return nil if raw_rows.nil? || raw_rows.empty?

    header_line = raw_rows[0]
    return nil unless header_line

    headers = normalize_headers(split_table_line(header_line))
    body_start = 1
    if raw_rows.length > 1 && separator_line?(raw_rows[1])
      body_start = 2
    end

    rows = raw_rows[body_start..].map { |line| split_table_line(line) }
    rows.reject! { |r| r.all?(&:empty?) }
    return nil if headers.empty?

    [headers, rows]
  end

  def split_table_line(line)
    line.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|").map(&:strip)
  end

  def separator_line?(line)
    split_table_line(line).all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }
  end

  def normalize_headers(headers)
    seen = {}
    headers.each_with_index.map do |header, i|
      name = sanitize_header_name(header)
      name = "Колонка #{i + 1}" if name.empty?
      name = name[0, 100] if name.length > 100
      if seen[name]
        seen[name] += 1
        name = "#{name} (#{seen[name]})"
      else
        seen[name] = 1
      end
      name
    end
  end

  def sanitize_header_name(header)
    name = header.to_s.gsub(/`+/, "").strip
    name = "№" if name == "#"
    name
  end

  NUMBER_HEADERS = ["№"].freeze

  def number_header?(header)
    NUMBER_HEADERS.include?(header.to_s)
  end

  def pick_title_header(headers)
    return "Name" if headers.empty?

    headers.find { |h| !number_header?(h) } || headers.first
  end

  def database_schema(headers)
    title_header = pick_title_header(headers)
    schema = {}
    headers.each do |header|
      schema[header] = case header
                       when title_header then { "name" => header, "type" => "title" }
                       when "№" then { "name" => header, "type" => "number" }
                       else { "name" => header, "type" => "rich_text" }
                       end
    end
    schema
  end

  def row_properties(headers, cells, parse_inline:)
    props = {}
    title_header = pick_title_header(headers)
    headers.each_with_index do |header, i|
      text = cells[i].to_s
      case header
      when title_header
        title_text = text.strip.empty? ? "—" : text
        props[header] = { "type" => "title", "title" => parse_inline.call(title_text) }
      when "№"
        num = text.gsub(/[^\d]/, "")
        props[header] = { "type" => "number", "number" => num.empty? ? nil : num.to_i }
      else
        props[header] = { "type" => "rich_text", "rich_text" => parse_inline.call(text) }
      end
    end
    props
  end

  def database_title(headers, index)
    base = headers.compact.join(" / ")
    base = "Таблица" if base.empty?
    index.positive? ? "#{base} (#{index + 1})" : base
  end

  def rich_text_title(text, parse_inline:)
    parse_inline.call(text)
  end

  def create_inline_database!(token, page_id:, title_rich_text:, headers:)
    BuildinApi.request!(token, :post, "/databases", {
      "parent" => { "page_id" => page_id },
      "is_inline" => true,
      "title" => title_rich_text,
      "properties" => database_schema(headers)
    })
  end

  def create_database_rows!(token, database_id:, headers:, rows_plain:, parse_inline:)
    rows_plain.each do |cells|
      props = row_properties(headers, cells, parse_inline: parse_inline)
      BuildinApi.request!(token, :post, "/pages", {
        "parent" => { "database_id" => database_id },
        "properties" => props
      })
      sleep BuildinApi::SLEEP_SEC
    end
  end

  def publish_table!(token, page_id:, headers:, rows_plain:, title_rich_text:, parse_inline:)
    db = create_inline_database!(token, page_id: page_id, title_rich_text: title_rich_text, headers: headers)
    create_database_rows!(token, database_id: db["id"], headers: headers, rows_plain: rows_plain, parse_inline: parse_inline)
    db
  end
end
