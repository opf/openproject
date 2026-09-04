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

module RecurringMeetings
  # A historic record of a previous schedule of a RecurringMeeting.
  # We need it to send out the updated old schedule with an UNTIL rule, so that the event correctly
  # ends for the clients.
  class HistoricSchedule < ApplicationRecord
    self.table_name = "recurring_meeting_historic_schedules"

    belongs_to :recurring_meeting

    validates :uid, presence: true, uniqueness: true
    validates :snapshot, presence: true

    store_attribute :snapshot, :dtstart, :datetime
    store_attribute :snapshot, :ends_at, :datetime
    store_attribute :snapshot, :tzid, :string
    store_attribute :snapshot, :duration, :float
    store_attribute :snapshot, :summary, :string
    store_attribute :snapshot, :location, :string
    store_attribute :snapshot, :rrule, :string
    store_attribute :snapshot, :sequence, :integer
    store_attribute :snapshot, :exdates, :json

    # exdates are stored as a string array, but we consume it in the schedule as datetime objects
    def exdates = Array(super).map { time_zone.parse(it) }

    def dtend = dtstart + duration.hours

    def time_zone = ActiveSupport::TimeZone[tzid] || Time.zone
  end
end
