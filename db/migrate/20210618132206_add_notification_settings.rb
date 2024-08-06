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

class AddNotificationSettings < ActiveRecord::Migration[6.1]
  def up
    create_table :notification_settings do |t|
      t.belongs_to :project, null: true, index: true, foreign_key: true
      t.belongs_to :user, null: false, index: true, foreign_key: true
      t.integer :channel, limit: 1
      t.boolean :watched, default: false
      t.boolean :involved, default: false
      t.boolean :mentioned, default: false
      t.boolean :all, default: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index %i[user_id channel],
              unique: true,
              where: "project_id IS NULL",
              name: "index_notification_settings_unique_project_null"

      t.index %i[user_id project_id channel],
              unique: true,
              where: "project_id IS NOT NULL",
              name: "index_notification_settings_unique_project"
    end

    remove_column :members, :mail_notification
    remove_column :users, :mail_notification
  end

  def down
    add_column :members, :mail_notification, :boolean, default: false, null: false
    add_column :users, :mail_notification, :string, default: "", null: false

    drop_table :notification_settings

    User.reset_column_information
    User.update_all(mail_notification: "only_assigned")
  end
end
