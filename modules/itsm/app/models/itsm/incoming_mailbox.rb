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
  class IncomingMailbox < ApplicationRecord
    include Mailbox

    PROTOCOL = "imap"

    belongs_to :connection, class_name: "ITSM::MailServer::Connection", inverse_of: :incoming_mailboxes, optional: false

    scope :with_any_alias, ->(addresses) { where(arel_table[:aliases].overlaps(addresses)) }

    normalizes :email, with: EmailAddress::NORMALIZE
    normalizes :aliases, with: EmailAddress::NORMALIZE_ALL

    validates :username, uniqueness: { scope: :connection_id, case_sensitive: false }
    validates :email, presence: true, uniqueness: true, email: { allow_blank: true }
    validates :aliases, email_list: true
    validate :email_is_not_an_alias_of_another_mailbox, if: -> { email.present? }
    validate :aliases_are_not_used_by_other_mailboxes, if: -> { aliases.any? }

    def known_addresses = [email, *aliases].compact_blank.uniq

    private

    def email_is_not_an_alias_of_another_mailbox
      errors.add(:email, :taken) if other_mailboxes.with_any_alias([email]).exists?
    end

    def aliases_are_not_used_by_other_mailboxes
      taken = other_mailboxes.where(email: aliases).or(other_mailboxes.with_any_alias(aliases))
      errors.add(:aliases, :taken) if taken.exists?
    end
  end
end
