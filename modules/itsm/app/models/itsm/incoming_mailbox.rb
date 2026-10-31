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
    RETRY_INTERVAL = 15.minutes
    MAX_RETRY_INTERVAL = 6.hours

    belongs_to :mail_server, class_name: "ITSM::MailServer", inverse_of: :incoming_mailboxes, optional: false

    scope :due_for_fetch, -> do
      where(active: true, next_fetch_at: [nil, ..Time.current], project: Project.active.has_module(:helpdesk))
    end

    normalizes :email, with: EmailAddress::NORMALIZE
    normalizes :aliases, with: EmailAddress::NORMALIZE_ALL

    validates :username, uniqueness: { scope: :mail_server_id, case_sensitive: false }
    validates :email, presence: true, uniqueness: true

    def fetch_succeeded!
      update_columns(last_fetched_at: Time.current, next_fetch_at: nil, consecutive_failures: 0, last_error: nil)
    end

    def fetch_failed!(code)
      failures = consecutive_failures + 1
      update_columns(consecutive_failures: failures, last_error: code, next_fetch_at: Time.current + retry_interval(failures))
    end

    private

    def retry_interval(failures) = [RETRY_INTERVAL * (2**failures), MAX_RETRY_INTERVAL].min
  end
end
