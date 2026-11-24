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
    DELIVERY_HEADERS = %w[Delivered-To X-Original-To].freeze

    def initialize(raw)
      @raw = raw
      @mail = Mail.new(raw)
    end

    def headers
      @headers ||= begin
        values = header_values.transform_values { Utf8Text.call(it) }
        Headers.new(**values,
                    from_address: EmailAddress.parse_all(Array(values[:from_address])).first,
                    to_addresses: EmailAddress.parse_all(values[:to_addresses]),
                    cc_addresses: EmailAddress.parse_all(values[:cc_addresses]))
      end
    end

    def text = @text ||= body.text

    def reply_text = @reply_text ||= body.reply_text

    def header_value(name) = Utf8Text.call(Array(mail.header[name]).first&.value)

    def delivery_addresses
      values = DELIVERY_HEADERS.flat_map { |name| Array(mail.header[name]).map { Utf8Text.call(it.value) } }
      EmailAddress.parse_all(values)
    end

    def report? = mail.mime_type == "multipart/report"

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

    def body = @body ||= Body.new(mail)

    def content_based_message_id = "#{Digest::SHA256.hexdigest(raw)}@openproject.invalid"
  end
end
