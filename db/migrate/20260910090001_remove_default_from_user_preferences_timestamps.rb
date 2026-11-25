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

# Up to OpenProject 16, Tables::UserPreferences declared the timestamps as
# t.timestamps default: DateTime.now, which froze the moment the migration ran
# into the column default. OpenProject 17 dropped the default from the table
# class without removing it from existing installations.
class RemoveDefaultFromUserPreferencesTimestamps < ActiveRecord::Migration[8.1]
  def up
    change_table :user_preferences, bulk: true do |t|
      t.change_default :created_at, nil
      t.change_default :updated_at, nil
    end
  end

  def down
    # No-op. The defaults held an arbitrary point in time per installation and
    # cannot be restored meaningfully.
  end
end
