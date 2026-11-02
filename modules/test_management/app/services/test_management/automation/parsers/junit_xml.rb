# frozen_string_literal: true

require "nokogiri"

module TestManagement
  module Automation
    module Parsers
      # JUnit XML (Playwright `--reporter=junit`, pytest, Maven Surefire, …).
      # Reference: "<classname>#<name>" (Playwright writes the spec file as classname
      # and "describe › title" as name, so references equal the JSON reporter's).
      # Parsed with NONET and without entity expansion; DTD entities are rejected.
      # JUnit XML has no test steps: only the test's failure message and trace are kept.
      class JunitXml
        ATTACHMENT = /\[\[ATTACHMENT\|(.+?)\]\]/

        def initialize(content)
          raise Error.new(:bad_request, "XML entity declarations are not allowed.") if content.match?(/<!ENTITY/i)

          @doc = Nokogiri::XML(content) { |config| config.strict.nonet }
        rescue Nokogiri::XML::SyntaxError => e
          raise Error.new(:bad_request, "The report is not valid XML: #{e.message.to_s.first(200)}")
        end

        def records
          @doc.xpath("//testcase").map { |node| build(node) }
        end

        private

        def build(node)
          name = node["name"].to_s
          classname = node["classname"].to_s
          file = node["file"].presence || classname
          failure = node.at_xpath("./failure") || node.at_xpath("./error")
          properties = properties_of(node)

          Record.new(
            reference: properties["tm_ref"]&.first.presence || "#{classname.presence || file}##{name}",
            title: name.split(PlaywrightJson::SEPARATOR).last.to_s.strip,
            title_path: name.split(PlaywrightJson::SEPARATOR).map(&:strip),
            file:,
            raw_status: status(node, failure),
            duration_ms: (node["time"].to_f * 1000).round,
            message: Json.clean(failure && (failure["message"].presence || failure.text.lines.first)),
            stack: Json.clean(failure&.text, Steps::TRACE_LIMIT * 2),
            tags: [],
            properties:,
            attachments: attachments(node)
          )
        end

        def status(node, failure)
          return "failed" if failure
          return "skipped" if node.at_xpath("./skipped")

          "passed"
        end

        def properties_of(node)
          node.xpath("./properties/property").each_with_object({}) do |prop, props|
            key = prop["name"].to_s.downcase
            next if key.blank?

            (props[key] ||= []) << (prop["value"].presence || prop.text).to_s
          end
        end

        def attachments(node)
          text = node.xpath("./system-out|./system-err").map(&:text).join("\n")
          text.scan(ATTACHMENT).flatten.uniq.map do |path|
            { "name" => File.basename(path), "path" => path.strip, "content_type" => "" }
          end
        end
      end
    end
  end
end
