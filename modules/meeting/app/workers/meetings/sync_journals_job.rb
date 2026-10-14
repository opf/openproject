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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Meetings
  # Records the current state of every meeting whose latest journal differs from it,
  # e.g. because sections and outcomes were not journaled before or a change was not journaled at all.
  class SyncJournalsJob < ApplicationJob
    def perform
      Journal::NotificationConfiguration.with(false) do
        Meeting.find_each { |meeting| sync(meeting) }
      end
    end

    private

    # Passing the cause to the journaling would force a journal even for meetings already in sync.
    def sync(meeting)
      journal = Journals::CreateService.new(meeting, User.system).call.result

      journal&.update_column(:cause, Journal::CausedBySystemUpdate.new(feature: "meeting_journal_sync").to_hash)
    end
  end
end
