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

class RenameAITextTransformActionsToTextActions < ActiveRecord::Migration[8.1]
  def up
    rename_table :ai_text_transform_actions, :ai_text_actions
    rename_table :ai_text_transform_action_types, :ai_text_action_types

    rename_column :ai_text_action_types, :ai_text_transform_action_id, :ai_text_action_id
    rename_column :ai_text_transform_runs, :ai_text_transform_action_id, :ai_text_action_id

    rename_index :ai_text_action_types,
                 "idx_ai_text_transform_action_types_on_action_and_type",
                 "idx_ai_text_action_types_on_action_and_type"

    rename_setting "ai_text_transform_actions_enabled", "ai_text_actions_enabled"
  end

  def down
    rename_setting "ai_text_actions_enabled", "ai_text_transform_actions_enabled"

    rename_index :ai_text_action_types,
                 "idx_ai_text_action_types_on_action_and_type",
                 "idx_ai_text_transform_action_types_on_action_and_type"

    rename_column :ai_text_transform_runs, :ai_text_action_id, :ai_text_transform_action_id
    rename_column :ai_text_action_types, :ai_text_action_id, :ai_text_transform_action_id

    rename_table :ai_text_action_types, :ai_text_transform_action_types
    rename_table :ai_text_actions, :ai_text_transform_actions
  end

  private

  def rename_setting(from, to)
    from = connection.quote(from)
    to = connection.quote(to)

    execute <<~SQL.squish
      DELETE FROM settings WHERE name = #{to} AND EXISTS (SELECT 1 FROM settings WHERE name = #{from})
    SQL
    execute <<~SQL.squish
      UPDATE settings SET name = #{to}, updated_at = NOW() WHERE name = #{from}
    SQL
  end
end
