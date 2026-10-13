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

    validates :skill_key, inclusion: { in: ->(_) { AI::AssistantSkills::Registry.keys } }
    validates :label, length: { maximum: 255 }
    validates :prompt, length: { maximum: 20_000 }

    # What the skill may propose: attribute changes and comments, comments only, or nothing.
    enum :proposal_scope, { changes: "changes", comment_only: "comment_only", read_only: "read_only" },
         default: "changes", validate: true, prefix: :scope

    # Where the skill is offered, as lists of ids. An empty list matches every work package.
    CONDITION_KEYS = %w[type_ids status_ids project_ids role_ids].freeze

    scope :active, -> { where(active: true) }

    def conditions=(value)
      ids = value.to_h.stringify_keys.slice(*CONDITION_KEYS)
                 .transform_values { |list| Array(list).compact_blank.map(&:to_i).uniq }
      super(ids.compact_blank)
    end

    def condition_ids(key)
      Array(conditions[key.to_s])
    end

    # Whether the work package and the user's roles in its project match every condition.
    def conditions_fulfilled?(work_package, user)
      condition_matches?(:type_ids) { [work_package.type_id] } &&
        condition_matches?(:status_ids) { [work_package.status_id] } &&
        condition_matches?(:project_ids) { [work_package.project_id] } &&
        condition_matches?(:role_ids) { user.roles_for_project(work_package.project).map(&:id) }
    end

    def skill_type
      AI::AssistantSkills::Registry.fetch(skill_key)
    end

    def chat?
      skill_type&.chat? || false
    end

    def conversation?
      skill_type&.conversation? || false
    end

    # Offered in the menu: every skill needs an LLM connection and a model, and a skill
    # that needs instructions also needs them set.
    def ready?
      return false if skill_type.nil?
      return false if skill_type.prompt_required? && prompt.blank?
      return false unless assistant.usable?

      LlmConnection.available? && assistant.effective_model_id.present?
    end

    # The action keys this skill may propose: none when read-only, a comment when
    # comment-only, otherwise what its type supports and a comment.
    def changeable_attributes
      return [] if skill_type.nil? || scope_read_only?
      return %w[comment] if scope_comment_only?

      skill_type.changeable_attributes + %w[comment]
    end

    # The admin's label or description, else the text of the skill type.
    def display_label
      label.presence || skill_type&.label || skill_key
    end

    # "OP assistant · Refresh work package": the title of its dialogs and history entries.
    def full_label
      "#{assistant.name} · #{display_label}"
    end

    def display_description
      description.presence || skill_type&.description
    end

    # The system prompt for a run, or nil when the skill has no prompt: the assistant's
    # instructions, the skill's prompt, and the output rules that the code owns.
    def system_prompt(locale:)
      full_system_prompt(locale:) if prompt.present?
    end

    # Also without a prompt, to show on the skill page.
    def full_system_prompt(locale:)
      [assistant&.instructions, prompt, AI::Assistance::OutputRules.new(self, locale:).to_s].compact_blank.join("\n\n")
    end

    private

    # The block gives the work package's ids for the key; it runs only for a set condition.
    def condition_matches?(key)
      condition_ids(key).empty? || condition_ids(key).intersect?(yield)
    end
  end
end
