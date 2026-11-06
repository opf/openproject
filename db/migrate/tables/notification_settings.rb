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

require_relative "base"

class Tables::NotificationSettings < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.belongs_to :project, null: true, index: true, foreign_key: true
      t.belongs_to :user, null: false, index: true, foreign_key: true
      t.boolean :watched, default: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :mentioned, default: true # rubocop:disable Rails/ThreeStateBooleanColumn

      t.timestamps precision: nil, default: -> { "CURRENT_TIMESTAMP" }

      # Adding indices here is probably useful as most of those are expected to be false
      # and we are searching for those that are true.
      # The columns watched, involved and mentioned will probably be true most of the time
      # so having an index there should not improve speed.
      t.boolean :work_package_commented, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :work_package_created, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :work_package_processed, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :work_package_prioritized, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :work_package_scheduled, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :news_added, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :news_commented, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :document_added, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :forum_messages, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :wiki_page_added, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :wiki_page_updated, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :membership_added, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :membership_updated, default: false, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.integer :start_date, default: 1
      t.integer :due_date, default: 1
      t.integer :overdue, default: nil
      t.boolean :assignee, default: true, null: false
      t.boolean :responsible, default: true, null: false
      t.boolean :shared, default: true, null: false

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
end
