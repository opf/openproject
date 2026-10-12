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

module AI
  class AssistantSkill < ApplicationRecord
    belongs_to :assistant, class_name: "AI::Assistant", inverse_of: :skills
    has_many :runs,
             class_name: "AI::AssistantRun",
             foreign_key: :skill_id,
             inverse_of: :skill,
             dependent: :destroy
    has_many :chats,
             class_name: "AI::AssistantChat",
             foreign_key: :skill_id,
             inverse_of: :skill,
             dependent: :destroy

    validates :skill_key, presence: true
    validates :label, :template_ref, length: { maximum: 255 }

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position, :id) }

    def skill_type
      AI::AssistantSkills::Registry.fetch(skill_key)
    end

    def chat?
      skill_type&.chat? || false
    end

    # Offered in the menu: a skill that needs instructions also needs them set, and a
    # chat also needs an LLM connection and a model.
    def ready?
      return false if skill_type.nil?
      return false if skill_type.prompt_required? && prompt.blank?
      return true unless chat?

      LlmConnection.available? && AI::AssistantRuns::ModelChoice.new(assistant).model_id.present?
    end

    # The attributes this skill may propose changes to: none when read-only, otherwise what
    # its type supports.
    def changeable_attributes
      read_only? ? [] : (skill_type&.changeable_attributes || [])
    end

    # The admin's label or description, else the text of the skill type.
    def display_label
      label.presence || skill_type&.label || skill_key
    end

    def display_description
      description.presence || skill_type&.description
    end

    # The system prompt for a run, or nil when no instructions are set. The output rules
    # may use {{locale}}; other placeholders stay as they are.
    def system_prompt(locale:)
      return if prompt.blank?

      rules = output_rules.to_s.gsub(/\{\{\s*(\w+)\s*\}\}/) do |match|
        Regexp.last_match(1) == "locale" ? locale.to_s : match
      end
      [prompt, rules].compact_blank.join("\n\n")
    end
  end
end
