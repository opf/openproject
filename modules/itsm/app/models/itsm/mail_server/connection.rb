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
  class MailServer
    class Connection < ApplicationRecord
      belongs_to :mail_server, class_name: "ITSM::MailServer", inverse_of: :connections, optional: false
      has_many :incoming_mailboxes, class_name: "ITSM::IncomingMailbox", inverse_of: :connection,
                                    dependent: :restrict_with_error
      has_many :outgoing_mailboxes, class_name: "ITSM::OutgoingMailbox", inverse_of: :connection,
                                    dependent: :restrict_with_error
      has_many :health_reports, as: :subject, dependent: :delete_all

      enum :protocol, { imap: "imap", smtp: "smtp" }, validate: true
      enum :encryption, { tls: "tls", starttls: "starttls" }, validate: true

      normalizes :host, with: ->(host) { host.strip.downcase.delete_suffix(".") }

      validates :protocol, uniqueness: { scope: :mail_server_id }
      validates :host, presence: true, hostname: true
      validates :port, numericality: { only_integer: true, in: 1..65_535 }
    end
  end
end
