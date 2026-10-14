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

# One skill type with settings, instead of a type for each use case: Refresh work package,
# Chat and Custom prompt become presets of a conversation.
class AddSettingsToAIAssistantSkills < ActiveRecord::Migration[8.1]
  PRESETS = {
    "health_check" => { answer_format: "findings", start: "preset", checks: true },
    "chat" => { answer_format: "text", start: "empty", checks: false },
    "prompt" => { answer_format: "text", start: "preset", checks: false }
  }.freeze

  def up
    add_column :ai_assistant_skills, :settings, :jsonb, null: false, default: {}

    PRESETS.each do |key, settings|
      execute <<~SQL.squish
        UPDATE ai_assistant_skills
        SET skill_key = 'conversation', settings = #{connection.quote(settings.to_json)}::jsonb
        WHERE skill_key = #{connection.quote(key)}
      SQL
    end
  end

  def down
    PRESETS.each do |key, settings|
      execute <<~SQL.squish
        UPDATE ai_assistant_skills SET skill_key = #{connection.quote(key)}
        WHERE skill_key = 'conversation'
          AND settings->>'answer_format' = #{connection.quote(settings[:answer_format])}
          AND settings->>'start' = #{connection.quote(settings[:start])}
      SQL
    end

    remove_column :ai_assistant_skills, :settings
  end
end
