# frozen_string_literal: true

module TestManagement
  module Automation
    # Picks the parser for `format` ("auto" detects it from the content) and
    # returns [format, records].
    module Parser
      FORMATS = %w[auto playwright_json junit native allure cucumber_json cucumber_messages].freeze

      module_function

      def parse(content, format = "auto")
        format = format.presence || "auto"
        unless FORMATS.include?(format)
          raise Error.new(:bad_request,
                          "Unknown format '#{format}'. Use one of: #{FORMATS.join(', ')}")
        end
        raise Error.new(:bad_request, "The report is empty.") if content.to_s.strip.empty?

        format = detect(content) if format == "auto"
        records = parser_for(format).new(content).records
        raise Error.new(:unprocessable, "The report contains no tests.") if records.empty?

        [format, records]
      end

      def detect(content)
        stripped = content.to_s.lstrip
        return "junit" if stripped.start_with?("<")
        return "cucumber_messages" if Parsers::CucumberMessages.detect?(stripped)

        data = Parsers::Json.load(stripped)
        return "playwright_json" if data.is_a?(Hash) && data["suites"].is_a?(Array)
        return "cucumber_json" if Parsers::CucumberJson.detect?(data)
        return "allure" if Parsers::Allure.detect?(data)
        return "native" if data.is_a?(Array) || (data.is_a?(Hash) && data["tests"].is_a?(Array))

        raise Error.new(:unprocessable, "Unknown report format. Send Playwright JSON, JUnit XML, Allure results, " \
                                        "Cucumber JSON or messages, or the native format.")
      end

      def parser_for(format)
        {
          "playwright_json" => Parsers::PlaywrightJson,
          "junit" => Parsers::JunitXml,
          "native" => Parsers::Native,
          "allure" => Parsers::Allure,
          "cucumber_json" => Parsers::CucumberJson,
          "cucumber_messages" => Parsers::CucumberMessages
        }.fetch(format)
      end
    end
  end
end
