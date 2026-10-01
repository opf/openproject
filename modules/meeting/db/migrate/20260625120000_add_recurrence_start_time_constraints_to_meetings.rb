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

class AddRecurrenceStartTimeConstraintsToMeetings < ActiveRecord::Migration[8.1]
  PRESENCE_CONSTRAINT = "recurrence_start_time_present_for_occurrences"
  ABSENCE_CONSTRAINT = "recurrence_start_time_absent_for_templates"

  # Mirror Meeting's model validations at the database level:
  #   presence: true, if: -> { recurring? && !template? }
  #   absence:  true, if: :template?
  def up
    # A non-template occurrence belonging to a series must have a recurrence_start_time.
    add_check_constraint :meetings,
                         "template OR recurring_meeting_id IS NULL OR recurrence_start_time IS NOT NULL",
                         name: PRESENCE_CONSTRAINT

    # A template must not have a recurrence_start_time.
    add_check_constraint :meetings,
                         "template = false OR recurrence_start_time IS NULL",
                         name: ABSENCE_CONSTRAINT
  end

  def down
    remove_check_constraint :meetings, name: PRESENCE_CONSTRAINT
    remove_check_constraint :meetings, name: ABSENCE_CONSTRAINT
  end
end
