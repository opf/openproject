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

module ITSM
  class InboundEmail
    class Body
      QUOTED_LINES = /(?:^[ \t]*>[^\n]*(?:\n|\z))+/
      # The line introducing a quote, such as "On … wrote:", and the blank lines after it.
      QUOTE_INTRO = /^[^\n]*\S:[ \t]*\n(?:[ \t]*\n)*/
      QUOTE = /(?:#{QUOTE_INTRO})?#{QUOTED_LINES}/

      def initialize(mail)
        @mail = mail
      end

      def text = extract(quotes: true)

      def reply_text = truncated(extract(quotes: false))

      private

      attr_reader :mail

      def instance_variables_to_inspect = []

      def extract(quotes:)
        parts = mail.multipart? ? body_parts("text/plain").presence || body_parts("text/html") : [mail]
        parts.map { part_text(it, quotes:).strip }.compact_blank.join("\n\n")
      end

      def body_parts(mime_type) = mail.all_parts.select { it.mime_type == mime_type && !it.attachment? }

      def part_text(part, quotes:)
        case part.mime_type
        when nil, "text/plain" then plain_text(decoded(part), quotes:)
        when "text/html" then HtmlToText.call(decoded(part), quotes:)
        else ""
        end
      end

      def decoded(part) = Utf8Text.call(part.decoded.to_s).gsub(/\r\n?/, "\n")

      # Several quotes mean answers between them, which need the quotes to be understood.
      def plain_text(text, quotes:)
        return text if quotes || text.scan(QUOTED_LINES).many?

        text.sub(QUOTE, "").gsub(/\n{3,}/, "\n\n")
      end

      def truncated(text)
        text = text.sub(/^[> \t]*#{Regexp.union(delimiters)}[ \t]*$.*/m, "") if delimiters.any?
        text = text.gsub(delimiter_regex, "") if delimiter_regex
        text.strip
      end

      def delimiters = Setting.mail_handler_body_delimiters.to_s.split(/[\r\n]+/).map(&:strip).compact_blank

      def delimiter_regex
        return @delimiter_regex if defined?(@delimiter_regex)

        source = Setting.mail_handler_body_delimiter_regex.presence
        @delimiter_regex = source && Regexp.new(source, Regexp::MULTILINE)
      rescue RegexpError
        @delimiter_regex = nil
      end
    end
  end
end
