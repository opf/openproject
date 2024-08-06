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

class ChangeNotificationSettingsStartDateDueDateAndOverdueDurationUnitToDays < ActiveRecord::Migration[7.0]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.change_default :start_date, from: 24, to: 1
      t.change_default :due_date, from: 24, to: 1
    end

    reversible do |dir|
      dir.up do
        update_durations_from_hours_to_days
      end

      dir.down do
        update_durations_from_days_to_hours
      end
    end
  end

  def update_durations_from_hours_to_days
    execute <<~SQL.squish
      UPDATE
        notification_settings
      SET
        start_date = CASE WHEN start_date IS NOT NULL THEN start_date / 24 END,
        due_date = CASE WHEN due_date IS NOT NULL THEN due_date / 24 END,
        overdue = CASE WHEN overdue IS NOT NULL THEN overdue / 24 END
    SQL
  end

  def update_durations_from_days_to_hours
    execute <<~SQL.squish
      UPDATE
        notification_settings
      SET
        start_date = CASE WHEN start_date IS NOT NULL THEN start_date * 24 END,
        due_date = CASE WHEN due_date IS NOT NULL THEN due_date * 24 END,
        overdue = CASE WHEN overdue IS NOT NULL THEN overdue * 24 END
    SQL
  end
end
