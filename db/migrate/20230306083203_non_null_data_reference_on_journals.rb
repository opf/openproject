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

class NonNullDataReferenceOnJournals < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        change_on_delete_on_notification_fk(true)
        cleanup_invalid_journals
      end
      direction.down do
        change_on_delete_on_notification_fk(false)
      end
    end

    change_non_null_data_columns
  end

  private

  def change_non_null_data_columns
    change_column_null :journals, :data_id, false
    change_column_null :journals, :data_type, false
  end

  def cleanup_invalid_journals
    execute <<~SQL.squish
      DELETE FROM journals
      WHERE data_id IS NULL OR data_type IS NULL
    SQL
  end

  def change_on_delete_on_notification_fk(cascade)
    options = if cascade
                { on_delete: :cascade }
              else
                {}
              end

    remove_foreign_key :notifications, :journals

    add_foreign_key :notifications,
                    :journals,
                    **options
  end
end
