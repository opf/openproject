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

class ScheduledMeeting < ApplicationRecord
  belongs_to :meeting, inverse_of: :scheduled_meeting
  belongs_to :recurring_meeting

  scope :upcoming, -> { where(start_time: Time.current..) }
  scope :past, -> { where(start_time: ...Time.current) }

  scope :instantiated, -> { where.not(meeting_id: nil) }
  scope :not_instantiated, -> { where(meeting_id: nil) }

  scope :cancelled, -> { where(cancelled: true) }
  scope :not_cancelled, -> { where(cancelled: false) }

  validates :meeting, uniqueness: { allow_nil: true }
  validates :start_time, presence: true

  def previous_occurrence
    recurring_meeting.previous_occurrence(from_time: start_time)
  end

  def next_occurrence
    recurring_meeting.next_occurrence(from_time: start_time)
  end
end
