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

class AddICalSequenceToRecurringMeetings < ActiveRecord::Migration[8.0]
  def change
    add_column :recurring_meetings, :ical_sequence, :integer, null: false, default: 0

    up_only do
      # The current value for sequence is the template's lock_version.
      # we use this as the seed for the current version to ensure the ICS output remains the same.
      execute <<~SQL.squish
        UPDATE recurring_meetings
        SET ical_sequence = COALESCE(
          (SELECT meetings.lock_version
           FROM meetings
           WHERE meetings.recurring_meeting_id = recurring_meetings.id
             AND meetings.template
           LIMIT 1),
          0
        )
      SQL
    end
  end
end
