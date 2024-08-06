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

class CleanupNotifications < ActiveRecord::Migration[6.1]
  def up
    change_table :notifications, bulk: true do |t|
      t.remove :read_mail, :reason_mail, :reason_mail_digest
      t.rename :reason_ian, :reason
      t.rename :read_mail_digest, :mail_reminder_sent
      t.boolean :mail_alert_sent, default: nil, index: true
    end

    change_table :notification_settings, bulk: true do |t|
      t.remove_index name: "index_notification_settings_unique_project_null"
      t.remove_index name: "index_notification_settings_unique_project"

      # Delete all non in-app
      NotificationSetting.where("channel > 0").delete_all

      t.remove :channel, :all

      t.index %i[user_id],
              unique: true,
              where: "project_id IS NULL",
              name: "index_notification_settings_unique_project_null"

      t.index %i[user_id project_id],
              unique: true,
              where: "project_id IS NOT NULL",
              name: "index_notification_settings_unique_project"
    end
  end

  def down
    change_table :notifications, bulk: true do |t|
      t.boolean :read_mail, default: false, index: true
      t.integer :reason_mail, limit: 1
      t.integer :reason_mail_digest, limit: 1
      t.rename :mail_reminder_sent, :read_mail_digest
      t.rename :reason, :reason_ian
    end

    change_table :notification_settings, bulk: true do |t|
      t.integer :channel, limit: 1
      t.boolean :all, default: false

      t.remove_index name: "index_notification_settings_unique_project_null"
      t.remove_index name: "index_notification_settings_unique_project"

      t.index %i[user_id channel],
              unique: true,
              where: "project_id IS NULL",
              name: "index_notification_settings_unique_project_null"

      t.index %i[user_id project_id channel],
              unique: true,
              where: "project_id IS NOT NULL",
              name: "index_notification_settings_unique_project"
    end
  end
end
