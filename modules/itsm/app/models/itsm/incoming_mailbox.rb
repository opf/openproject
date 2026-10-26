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
    FETCH_INTERVAL = 15.minutes
    MAX_FETCH_INTERVAL = 6.hours

    belongs_to :mail_server, class_name: "ITSM::MailServer", inverse_of: :incoming_mailboxes, optional: false

    scope :due_for_fetch, -> { where(active: true, next_fetch_at: [nil, ..Time.current]) }

    normalizes :email, with: EmailAddress::NORMALIZE
    normalizes :aliases, with: EmailAddress::NORMALIZE_ALL

    validates :username, uniqueness: { scope: :mail_server_id, case_sensitive: false }
    validates :email, presence: true, uniqueness: true

    def imap_authentication = Adapters::AuthenticationStrategies::BasicAuth.new(credentials)

    def fetch_succeeded!
      now = Time.current
      update_columns(last_fetched_at: now, next_fetch_at: now + FETCH_INTERVAL, consecutive_failures: 0, last_error: nil)
    end

    def fetch_failed!(code)
      failures = consecutive_failures + 1
      update_columns(consecutive_failures: failures, last_error: code, next_fetch_at: Time.current + retry_interval(failures))
    end

    private

    def retry_interval(failures) = [FETCH_INTERVAL * (2**failures), MAX_FETCH_INTERVAL].min
  end
end
