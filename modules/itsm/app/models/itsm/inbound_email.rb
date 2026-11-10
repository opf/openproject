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
    Headers = Data.define(:message_id, :in_reply_to, :references, :from_address, :from_name,
                          :to_addresses, :cc_addresses, :subject)

    def initialize(raw)
      @raw = raw
      @mail = Mail.new(raw)
    end

    def headers
      @headers ||= begin
        values = header_values.transform_values { valid_utf8(it) }
        Headers.new(**values,
                    from_address: email_addresses(Array(values[:from_address])).first,
                    to_addresses: email_addresses(values[:to_addresses]),
                    cc_addresses: email_addresses(values[:cc_addresses]))
      end
    end

    def text
      @text ||= body_text.gsub(/\r\n?/, "\n").strip
    end

    def header_value(name) = valid_utf8(Array(mail.header[name]).first&.value)

    def delivery_addresses
      email_addresses(%w[Delivered-To X-Original-To].filter_map { header_value(it)&.delete("<>") })
    end

    def delivery_report?
      mail.mime_type == "multipart/report" && mail.content_type_parameters["report-type"]&.casecmp?("delivery-status")
    end

    private

    attr_reader :raw, :mail

    def instance_variables_to_inspect = []

    def header_values # rubocop:disable Metrics/AbcSize
      {
        message_id: mail.message_id.presence || content_based_message_id,
        in_reply_to: Array(mail.in_reply_to).first,
        references: Array(mail.references),
        from_address: Array(mail.from).first,
        from_name:,
        to_addresses: Array(mail.to),
        cc_addresses: Array(mail.cc),
        subject: mail.subject
      }
    end

    def from_name
      field = mail[:from]&.field
      field.display_names.first if field.is_a?(Mail::FromField)
    end

    def body_text
      return part_text(mail) unless mail.multipart?

      parts = body_parts("text/plain").presence || body_parts("text/html")
      parts.map { part_text(it).strip }.compact_blank.join("\n\n")
    end

    def body_parts(mime_type) = mail.all_parts.select { it.mime_type == mime_type && !it.attachment? }

    def part_text(part)
      case part.mime_type
      when nil, "text/plain" then valid_utf8(part.decoded.to_s)
      when "text/html" then HtmlToText.call(valid_utf8(part.decoded))
      else ""
      end
    end

    def email_addresses(addresses) = EmailAddress::NORMALIZE_ALL.call(addresses.select { EmailValidator.valid?(it) })

    def content_based_message_id = "#{Digest::SHA256.hexdigest(raw)}@openproject.invalid"

    def valid_utf8(value)
      case value
      when Array then value.map { valid_utf8(it) }
      when String then value.dup.force_encoding(Encoding::UTF_8).scrub.delete("\u0000")
      else value
      end
    end
  end
end
