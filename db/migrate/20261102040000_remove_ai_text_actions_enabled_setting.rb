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

class RemoveAITextActionsEnabledSetting < ActiveRecord::Migration[8.1]
  ENV_SETTING_NAMES = %w[ai_text_actions_enabled ai_text_transform_actions_enabled].freeze

  def up
    unless enabled_in_database? || enabled_in_environment?
      execute "UPDATE ai_text_actions SET active = false, updated_at = NOW()"
    end

    execute "DELETE FROM settings WHERE name = 'ai_text_actions_enabled'"
  end

  def down
    execute <<~SQL.squish
      INSERT INTO settings (name, value, updated_at)
      SELECT 'ai_text_actions_enabled', '1', NOW()
      WHERE NOT EXISTS (SELECT 1 FROM settings WHERE name = 'ai_text_actions_enabled')
    SQL
  end

  private

  def enabled_in_database?
    connection.select_value(<<~SQL.squish) == 1
      SELECT 1 FROM settings
      WHERE name = 'ai_text_actions_enabled' AND value IN ('1', 't', 'true')
      LIMIT 1
    SQL
  end

  def enabled_in_environment?
    ENV_SETTING_NAMES.any? do |name|
      [name.upcase.gsub("_", "__"), name.upcase].any? do |key|
        value = ENV.fetch("OPENPROJECT_#{key}", nil)
        value.present? && YAML.safe_load(value) == true
      rescue Psych::Exception
        false
      end
    end
  end
end
