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
  class MailServer < ApplicationRecord
    has_many :connections, class_name: "ITSM::MailServer::Connection", inverse_of: :mail_server, dependent: :destroy
    has_one :imap_connection, -> { imap }, class_name: "ITSM::MailServer::Connection", inverse_of: :mail_server,
                                           autosave: true, dependent: nil
    has_one :smtp_connection, -> { smtp }, class_name: "ITSM::MailServer::Connection", inverse_of: :mail_server,
                                           autosave: true, dependent: nil

    before_destroy :ensure_no_mailbox_uses_it, prepend: true

    validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
    validates :imap_connection, :smtp_connection, presence: true
    # Community edition limit: more mail servers need the Enterprise edition (ITSM-21).
    validate :no_other_mail_server, on: :create

    def in_use? = IncomingMailbox.exists?(connection: connections) || OutgoingMailbox.exists?(connection: connections)

    private

    def no_other_mail_server
      errors.add(:base, :mail_server_limit_reached) if self.class.exists?
    end

    def ensure_no_mailbox_uses_it
      return unless in_use?

      errors.add(:base, :"restrict_dependent_destroy.has_many", record: self.class.human_attribute_name(:mailboxes))
      throw :abort
    end
  end
end
