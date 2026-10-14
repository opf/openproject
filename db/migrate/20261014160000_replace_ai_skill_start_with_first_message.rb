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

# A skill opens the chat and sends its first message, or opens an empty chat. Whether it
# lists findings is up to its instructions; the built-in checks stay a setting.
class ReplaceAISkillStartWithFirstMessage < ActiveRecord::Migration[8.1]
  def up
    each_skill do |label, settings|
      first_message = settings["start"] == "empty" ? nil : label.presence || default_first_message(settings)
      { "checks" => settings["checks"] == true, "first_message" => first_message }.compact
    end
  end

  def down
    each_skill do |_label, settings|
      { "start" => settings["first_message"].present? ? "preset" : "empty",
        "answer_format" => settings["checks"] ? "findings" : "text",
        "checks" => settings["checks"] == true }
    end
  end

  private

  def each_skill
    select_rows("SELECT id, label, settings FROM ai_assistant_skills").each do |id, label, settings|
      updated = yield(label, JSON.parse(settings.presence || "{}"))
      execute "UPDATE ai_assistant_skills SET settings = #{quote(updated.to_json)}::jsonb WHERE id = #{Integer(id)}"
    end
  end

  def default_first_message(settings)
    settings["answer_format"] == "findings" ? "Review this work package." : "Run your instructions on this work package."
  end
end
