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

require "nokogiri"

module TestManagement
  module Automation
    module Parsers
      class JunitXml
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

        def build(node) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
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
            stack: Json.clean(failure&.text, TestResult::ERROR_TRACE_LIMIT),
            tags: [],
            properties:
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
      end
    end
  end
end
