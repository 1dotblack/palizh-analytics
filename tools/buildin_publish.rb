# frozen_string_literal: true

# Общая публикация MD → Buildin: блоки и inline database.
# require из sync_buildin_export.rb и publish_* скриптов.

require "json"
require "net/http"
require "uri"

require_relative "buildin_api"
require_relative "md_table_database"

REPO = File.expand_path("..", __dir__)
CHUNK_SIZE = 100
SLEEP_SEC = 0.35

def load_buildin_token
  return ENV["BUILDIN_API_TOKEN"] if ENV["BUILDIN_API_TOKEN"] && !ENV["BUILDIN_API_TOKEN"].empty?

  mcp_path = File.expand_path("~/.cursor/mcp.json")
  if File.file?(mcp_path)
    cfg = JSON.parse(File.read(mcp_path))
    url = cfg.dig("mcpServers", "Buildin", "url").to_s
    tok = url[/token=([^&]+)/, 1]
    return tok if tok && !tok.empty?
  end

  nil
end

def load_buildin_target
  path = File.join(REPO, "export", "buildin", "BUILDIN_TARGET")
  vars = {}
  File.readlines(path, encoding: "UTF-8").each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")

    k, v = line.split("=", 2)
    vars[k] = v
  end
  vars
end

def buildin_plain_annotations
  {
    "bold" => false, "italic" => false, "strikethrough" => false,
    "underline" => false, "code" => false, "color" => "default"
  }
end

def buildin_title_property(text)
  {
    "title" => {
      "type" => "title",
      "title" => [{
        "type" => "text",
        "text" => { "content" => text, "link" => nil },
        "annotations" => buildin_plain_annotations,
        "plain_text" => text,
        "href" => nil
      }]
    }
  }
end

def buildin_callout_block(text, emoji: "ℹ️")
  {
    "object" => "block",
    "type" => "callout",
    "callout" => {
      "rich_text" => [{
        "type" => "text",
        "text" => { "content" => text, "link" => nil },
        "annotations" => buildin_plain_annotations,
        "plain_text" => text,
        "href" => nil
      }],
      "icon" => { "type" => "emoji", "emoji" => emoji }
    }
  }
end

def buildin_api_request(token, method, path, body = nil, idempotency_key: nil, retries: 3)
  uri = URI("#{BuildinApi::API_BASE}#{path}")
  klass = case method
          when :get then Net::HTTP::Get
          when :post then Net::HTTP::Post
          when :patch then Net::HTTP::Patch
          else raise "method #{method}"
          end

  attempt = 0
  loop do
    attempt += 1
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 30
    http.read_timeout = 120
    req = klass.new(uri)
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"
    req["Idempotency-Key"] = idempotency_key if idempotency_key
    req.body = JSON.generate(body) if body

    res = http.request(req)
    code = res.code.to_i

    if code == 429 && attempt <= retries
      warn "  rate limit, пауза 5с…"
      sleep 5
      next
    end

    unless code.between?(200, 299)
      raise "API #{method.upcase} #{path} → #{code}: #{res.body[0, 500]}"
    end

    return JSON.parse(res.body) if res.body && !res.body.empty?

    return {}
  end
end

def buildin_create_page_title_only(token, parent_id:, title:, icon:, idempotency_key: nil)
  buildin_api_request(token, :post, "/pages", {
    "parent" => { "page_id" => parent_id },
    "icon" => { "type" => "emoji", "emoji" => icon },
    "properties" => buildin_title_property(title)
  }, idempotency_key: idempotency_key)
end

def buildin_append_blocks(token, page_id, blocks)
  return if blocks.nil? || blocks.empty?

  blocks.each_slice(CHUNK_SIZE) do |chunk|
    sleep SLEEP_SEC
    buildin_api_request(token, :patch, "/blocks/#{page_id}/children", { "children" => chunk })
  end
end

def buildin_publish_content_sequence(token, page_id, sequence)
  sequence.each do |item|
    case item["kind"]
    when "blocks"
      buildin_append_blocks(token, page_id, item["blocks"])
    when "database"
      MdTableDatabase.publish_table!(
        token,
        page_id: page_id,
        headers: item["headers"],
        rows_plain: item["rows"],
        title_rich_text: parse_inline(item["title"]),
        parse_inline: ->(text) { parse_inline(text) }
      )
      warn "    database «#{item['title']}»: #{item['rows'].length} строк" if $VERBOSE
    end
  end
end
