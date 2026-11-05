# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  module Automation
    module Parser
      FORMATS = %w[auto junit playwright_json native].freeze

      module_function

      def parse(content, format = "auto") # rubocop:disable Metrics/AbcSize
        format = format.presence || "auto"
        unless FORMATS.include?(format)
          raise Error.new(:bad_request, "Unknown format '#{format}'. Use one of: #{FORMATS.join(', ')}")
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

        data = Parsers::Json.load(stripped)
        return "playwright_json" if data.is_a?(Hash) && data["suites"].is_a?(Array)
        return "native" if data.is_a?(Array) || (data.is_a?(Hash) && data["tests"].is_a?(Array))

        raise Error.new(:unprocessable, "Unknown report format. Send Playwright JSON, JUnit XML or the native format.")
      end

      def parser_for(format)
        { "playwright_json" => Parsers::PlaywrightJson, "junit" => Parsers::JunitXml,
          "native" => Parsers::Native }.fetch(format)
      end
    end
  end
end
