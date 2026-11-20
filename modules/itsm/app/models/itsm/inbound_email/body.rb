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
      # A block of quoted "> " lines, with the line introducing it ("On … wrote:").
      QUOTE = /^(?:[^\n]*\S:[ \t]*\n(?:[ \t]*\n)*)?(?:[ \t]*>[^\n]*(?:\n|\z))+/

      def initialize(mail)
        @mail = mail
      end

      def text = normalized(extract(quotes: true))

      def reply_text = normalized(extract(quotes: false))

      private

      attr_reader :mail

      def instance_variables_to_inspect = []

      def normalized(text) = text.gsub(/\r\n?/, "\n").strip

      def extract(quotes:)
        return part_text(mail, quotes:) unless mail.multipart?

        parts = body_parts("text/plain").presence || body_parts("text/html")
        parts.map { part_text(it, quotes:).strip }.compact_blank.join("\n\n")
      end

      def body_parts(mime_type) = mail.all_parts.select { it.mime_type == mime_type && !it.attachment? }

      def part_text(part, quotes:)
        case part.mime_type
        when nil, "text/plain" then plain_text(Utf8Text.call(part.decoded.to_s), quotes:)
        when "text/html" then HtmlToText.call(Utf8Text.call(part.decoded), quotes:)
        else ""
        end
      end

      def plain_text(text, quotes:) = quotes ? text : text.gsub(/\r\n?/, "\n").gsub(QUOTE, "").gsub(/\n{3,}/, "\n\n")
    end
  end
end
