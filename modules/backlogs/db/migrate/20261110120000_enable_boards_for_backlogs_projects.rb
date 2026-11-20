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

class EnableBoardsForBacklogsProjects < ActiveRecord::Migration[8.1]
  class MigrationSetting < ApplicationRecord
    self.table_name = "settings"
  end

  def up
    say_with_time "Enabling the boards module in projects that have backlogs enabled" do
      execute <<~SQL.squish
        INSERT INTO enabled_modules (project_id, name)
        SELECT backlogs.project_id, 'board_view'
        FROM enabled_modules backlogs
        WHERE backlogs.name = 'backlogs'
          AND NOT EXISTS (
            SELECT 1
            FROM enabled_modules boards
            WHERE boards.project_id = backlogs.project_id
              AND boards.name = 'board_view'
          )
      SQL
    end

    say_with_time "Adding the boards module to the default modules for new projects" do
      add_boards_to_default_project_modules
    end
  end

  def down; end

  private

  def add_boards_to_default_project_modules
    setting = MigrationSetting
                .where(name: "default_projects_modules")
                .where("value LIKE ? AND value NOT LIKE ?", "%backlogs%", "%board_view%")
                .first
    return if setting.nil?

    modules = YAML.safe_load(setting.value, permitted_classes: [Symbol])
    return unless modules.is_a?(Array)
    return if modules.exclude?("backlogs") || modules.include?("board_view")

    setting.update!(value: (modules + %w[board_view]).to_yaml)
  end
end
