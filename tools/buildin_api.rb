# frozen_string_literal: true

# Общие вызовы Buildin API v2 для выгрузки документации.
# require_relative "buildin_api" из tools/*.rb

require "json"
require "net/http"
require "uri"

module BuildinApi
  API_BASE = ENV.fetch("BUILDIN_API_BASE", "https://api.buildin.ai/v2")
  SLEEP_SEC = 0.35

  module_function

  def load_token
    return ENV["BUILDIN_API_TOKEN"] if ENV["BUILDIN_API_TOKEN"] && !ENV["BUILDIN_API_TOKEN"].empty?

    mcp_path = File.expand_path("~/.cursor/mcp.json")
    if File.file?(mcp_path)
      url = JSON.parse(File.read(mcp_path)).dig("mcpServers", "Buildin", "url").to_s
      tok = url[/token=([^&]+)/, 1]
      return tok if tok && !tok.empty?
    end

    nil
  end

  def request(token, method, path, body = nil, idempotency_key: nil)
    uri = URI("#{API_BASE}#{path}")
    klass = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      patch: Net::HTTP::Patch,
      put: Net::HTTP::Put,
      delete: Net::HTTP::Delete
    }.fetch(method)

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
    parsed = res.body && !res.body.empty? ? JSON.parse(res.body) : {}
    [res.code.to_i, parsed]
  end

  def request!(token, method, path, body = nil, idempotency_key: nil)
    code, parsed = request(token, method, path, body, idempotency_key: idempotency_key)
    return parsed if code.between?(200, 299)

    msg = parsed.is_a?(Hash) ? parsed["message"] : parsed.to_s
    raise "API #{method.upcase} #{path} → #{code}: #{msg}"
  end

  def get_page_markdown(token, page_id)
    request!(token, :get, "/pages/#{page_id}/content/markdown")
  end

  # Запись тела страницы Markdown (как при вставке в UI).
  # В OpenAPI v2 (2026-06) зарегистрирован только GET; PUT может появиться позже.
  def put_page_markdown(token, page_id, markdown)
    code, parsed = request(token, :put, "/pages/#{page_id}/content/markdown", { "markdown" => markdown })
  case code
    when 200, 201, 204 then :ok
    when 404 then :not_found
    else
      msg = parsed.is_a?(Hash) ? parsed["message"] : parsed.to_s
      raise "PUT markdown → #{code}: #{msg}"
    end
  end

  def markdown_write_available?(token, probe_page_id: nil)
    return true if ENV["BUILDIN_MARKDOWN_WRITE"] == "1"
    return false if ENV["BUILDIN_MARKDOWN_WRITE"] == "0"

    @markdown_write_available = :not_found if defined?(@markdown_write_available) && @markdown_write_available == :not_found
    return @markdown_write_available == :ok if defined?(@markdown_write_available) && @markdown_write_available

    pid = probe_page_id
    unless pid
      code, _ = request(token, :get, "/users/me")
      return (@markdown_write_available = :not_found) unless code == 200
      return (@markdown_write_available = :not_found)
    end

    @markdown_write_available = put_page_markdown(token, pid, "# probe\n")
    @markdown_write_available
  end

  def list_block_children(token, block_id, page_size: 100)
    results = []
    cursor = nil
    loop do
      q = cursor ? "?page_size=#{page_size}&start_cursor=#{cursor}" : "?page_size=#{page_size}"
      data = request!(token, :get, "/blocks/#{block_id}/children#{q}")
      results.concat(data["results"] || [])
      break unless data["has_more"]

      cursor = data["next_cursor"]
    end
    results
  end

  def delete_block(token, block_id)
    request!(token, :patch, "/blocks/#{block_id}", { "in_trash" => true })
  end

  def clear_page_content(token, page_id)
    list_block_children(token, page_id).each do |block|
      sleep SLEEP_SEC
      delete_block(token, block["id"])
    end
  end

  def replace_page_markdown(token, page_id, markdown)
    status = put_page_markdown(token, page_id, markdown)
    return :ok if status == :ok

    :not_found
  end

  def table_block_empty?(token, table_block_id)
    rows = list_block_children(token, table_block_id)
    return true if rows.empty?

    rows.all? do |row|
      next true unless row["type"] == "table_row"

      cells = row.dig("table_row", "cells") || []
      cells.all? { |cell| cell.empty? || cell.all? { |rt| rt["plain_text"].to_s.empty? } }
    end
  end

  def page_has_empty_tables?(token, page_id)
    list_block_children(token, page_id).any? do |block|
      block["type"] == "table" && table_block_empty?(token, block["id"])
    end
  end

  def trash_page(token, page_id)
    request!(token, :patch, "/pages/#{page_id}", { "in_trash" => true })
  end

  # Полная очистка страницы Cursor: дочерние страницы из PAGE_MAP + блоки на корне.
  def clear_cursor_export!(token, root_id, page_map)
    page_ids = []
    (page_map["documents"] || {}).each_value { |d| page_ids << d["page_id"] }
    (page_map["sections"] || {}).each_value { |s| page_ids << s["page_id"] }
    page_ids.uniq!
    page_ids.delete(root_id)

    page_ids.each do |pid|
      trash_page(token, pid)
      sleep SLEEP_SEC
    rescue StandardError => e
      warn "  пропуск удаления #{pid}: #{e.message}"
    end

    clear_page_content(token, root_id)

    page_map["sections"] = {}
    page_map["documents"] = {}
    page_map["root_page_id"] = root_id
    page_map
  end
end
