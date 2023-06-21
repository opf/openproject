#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
#

class MeetingAgendaTop < ApplicationRecord
  belongs_to :meeting
  has_one :project, through: :meeting
  belongs_to :user

  acts_as_list scope: :meeting
  default_scope { order(:position) }

  validates :title, presence: true
  validates :duration_in_minutes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_create :trigger_meeting_agenda_top_time_slots_calculation
  after_save :trigger_meeting_agenda_top_time_slots_calculation, if: Proc.new { |top| top.duration_in_minutes_previously_changed? || top.position_previously_changed? }
  after_destroy :trigger_meeting_agenda_top_time_slots_calculation

  def trigger_meeting_agenda_top_time_slots_calculation
    meeting.calculate_agenda_top_time_slots
  end
end
