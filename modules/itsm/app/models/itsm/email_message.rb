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
  class EmailMessage < ApplicationRecord
    # RFC 5322 limits a header line to 998 bytes, which also fits the indexes on the Message-ID.
    MESSAGE_ID_MAX_BYTES = 998
    STATUSES = {
      "inbound" => %w[received processed ignored failed],
      "outbound" => %w[queued sent failed]
    }.freeze

    belongs_to :thread, class_name: "ITSM::EmailThread", inverse_of: :messages, optional: false
    belongs_to :journal, optional: true

    enum :direction, { inbound: "inbound", outbound: "outbound" }, validate: true
    enum :status,
         {
           received: "received",
           processed: "processed",
           ignored: "ignored",
           queued: "queued",
           sent: "sent",
           failed: "failed"
         },
         validate: true

    normalizes :from_address, with: EmailAddress::NORMALIZE
    normalizes :to_addresses, :cc_addresses, with: EmailAddress::NORMALIZE_ALL

    validates :message_id, presence: true, uniqueness: { scope: :thread_id }
    validate :message_id_fits_a_header_line
    validates :status, inclusion: { in: ->(message) { STATUSES.fetch(message.direction, []) } }
    validates :from_address, presence: true

    private

    def message_id_fits_a_header_line
      return if message_id.to_s.bytesize <= MESSAGE_ID_MAX_BYTES

      errors.add(:message_id, :too_long, count: MESSAGE_ID_MAX_BYTES)
    end
  end
end
