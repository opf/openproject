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
  class Mailbox < ApplicationRecord
    belongs_to :mail_server, class_name: "ITSM::MailServer", inverse_of: :mailboxes, optional: false
    belongs_to :project, optional: false
    has_many :threads, class_name: "ITSM::EmailThread", inverse_of: :mailbox, dependent: :nullify
    has_many :messages, class_name: "ITSM::EmailMessage", inverse_of: :mailbox, dependent: :nullify

    before_destroy :delete_messages_without_thread, prepend: true

    scope :with_any_alias, ->(addresses) { where(arel_table[:aliases].overlaps(addresses)) }

    self.filter_attributes += %i[password]

    normalizes :email, with: ->(email) { email.strip.downcase }
    normalizes :aliases, with: ->(aliases) { aliases.map { it.strip.downcase }.compact_blank.uniq }
    normalizes :imap_username, :smtp_username, with: ->(username) { username.strip }

    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validate :aliases_are_email_addresses
    validate :email_is_not_an_alias_of_another_mailbox, if: -> { email.present? }
    validate :aliases_are_not_used_by_other_mailboxes, if: -> { aliases.any? }
    validates :imap_username, presence: true, uniqueness: { scope: :mail_server_id, case_sensitive: false }
    validates :smtp_username, presence: true
    validates :imap_password, :smtp_password, presence: true

    def known_addresses = [email, *aliases].compact_blank.uniq

    def imap_credentials = Credentials.new(username: imap_username, password: imap_password)
    def smtp_credentials = Credentials.new(username: smtp_username, password: smtp_password)

    private

    def aliases_are_email_addresses
      errors.add(:aliases, :invalid) unless aliases.all? { it.match?(URI::MailTo::EMAIL_REGEXP) }
    end

    def email_is_not_an_alias_of_another_mailbox
      errors.add(:email, :taken) if other_mailboxes.with_any_alias([email]).exists?
    end

    def aliases_are_not_used_by_other_mailboxes
      taken = other_mailboxes.where(email: aliases).or(other_mailboxes.with_any_alias(aliases))
      errors.add(:aliases, :taken) if taken.exists?
    end

    def other_mailboxes = self.class.where.not(id:)

    def delete_messages_without_thread
      messages.where(thread_id: nil).delete_all
    end
  end
end
