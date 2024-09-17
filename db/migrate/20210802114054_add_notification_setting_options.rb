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

class AddNotificationSettingOptions < ActiveRecord::Migration[6.1]
  def change
    add_notification_settings_options
  end

  def add_notification_settings_options
    change_table :notification_settings, bulk: true do |t|
      # Adding indices here is probably useful as most of those are expected to be false
      # and we are searching for those that are true.
      # The columns watched, involved and mentioned will probably be true most of the time
      # so having an index there should not improve speed.
      t.boolean :work_package_commented, default: false, index: true
      t.boolean :work_package_created, default: false, index: true
      t.boolean :work_package_processed, default: false, index: true
      t.boolean :work_package_prioritized, default: false, index: true
      t.boolean :work_package_scheduled, default: false, index: true
      t.index :all
    end
  end
end
