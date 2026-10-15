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
    has_many :chats,
             class_name: "AI::AssistantChat",
             foreign_key: :skill_id,
             inverse_of: :skill,
             dependent: :destroy

    # Work packages: only on a work package. Everywhere: also on every other page, without
    # proposals there (see #offered_at?).
    OFFERED_ON = %w[work_packages everywhere].freeze
    # Conditions that need a work package, so an Everywhere skill has none.
    WORK_PACKAGE_CONDITIONS = %w[type_ids status_ids].freeze

    ICONS = %w[light-bulb comment-discussion sync checklist tasklist search pencil beaker bug
               graph shield-check megaphone book rocket].freeze

    validates :skill_key, inclusion: { in: ->(_) { AI::AssistantSkills::Registry.keys } }
    validates :label, length: { maximum: 255 }
    validates :prompt, length: { maximum: 20_000 }
    validates :icon, inclusion: { in: ICONS }, allow_blank: true
    validates :offered_on, inclusion: { in: OFFERED_ON }

    # Opening the skill starts a new chat, and the skill answers its instructions at once.
    # Without it, the skill opens an empty chat for the user's own questions.
    store_attribute :settings, :answers_at_once, :boolean, default: true
    # Off: the model sees only the work package context, without the read-only MCP tools.
    store_attribute :settings, :use_tools, :boolean, default: true
    # An Octicon for the menu and the history. Empty uses the icon of the variant.
    store_attribute :settings, :icon, :string
    store_attribute :settings, :offered_on, :string, default: "work_packages"

    # What the skill may propose: attribute changes and comments, comments only, or nothing.
    enum :proposal_scope, { changes: "changes", comment_only: "comment_only", read_only: "read_only" },
         default: "changes", validate: true, prefix: :scope

    # Where the skill is offered, as lists of ids. An empty list matches every work package.
    CONDITION_KEYS = %w[type_ids status_ids project_ids role_ids].freeze
    CONDITION_MODELS = { "type_ids" => Type, "status_ids" => Status, "project_ids" => Project, "role_ids" => Role }.freeze

    scope :active, -> { where(active: true) }

    before_save :drop_deleted_condition_ids
    before_save :drop_work_package_conditions, if: :everywhere?

    def conditions=(value)
      ids = value.to_h.stringify_keys.slice(*CONDITION_KEYS)
                 .transform_values { |list| Array(list).compact_blank.map(&:to_i).uniq }
      super(ids.compact_blank)
    end

    def condition_ids(key)
      Array(conditions[key.to_s])
    end

    # A copy at the end of the assistant's skills. A single copy is renamed and inactive; the
    # skills of a copied assistant stay as they are.
    def copy!(assistant: self.assistant, rename: true)
      copy = dup
      copy.assign_attributes(assistant:, settings: settings.deep_dup, conditions: conditions.deep_dup,
                             position: (assistant.skills.maximum(:position) || 0) + 1)
      if rename
        copy.assign_attributes(label: I18n.t("admin.ai_assistants.copy_name", name: display_label).truncate(255),
                               active: false)
      end
      copy.save!
      copy
    end

    # Skills saved before the setting existed have none.
    def offered_on
      super.presence || "work_packages"
    end

    def everywhere? = offered_on == "everywhere"

    # Whether the skill is offered at the place. On a work package, every skill whose
    # conditions match. Elsewhere, only an Everywhere skill, and one limited to projects or
    # roles only in a matching project.
    def offered_at?(place, user)
      return conditions_fulfilled?(place.work_package, user) if place.work_package
      return false unless everywhere?

      project = place.project
      condition_matches?(:project_ids) { [project&.id] } &&
        (condition_ids(:role_ids).empty? || (project.present? && (user.admin? || role_matches?(project, user))))
    end

    # Whether the work package and the user's roles in its project match every condition.
    def conditions_fulfilled?(work_package, user)
      condition_matches?(:type_ids) { [work_package.type_id] } &&
        condition_matches?(:status_ids) { [work_package.status_id] } &&
        condition_matches?(:project_ids) { [work_package.project_id] } &&
        (user.admin? || role_matches?(work_package.project, user))
    end

    def skill_type
      AI::AssistantSkills::Registry.fetch(skill_key)
    end

    # Opens an empty chat instead of answering at once.
    def chat?
      !answers_at_once
    end

    # chat or preset: the default label, the description and the icon.
    def variant
      chat? ? "chat" : "preset"
    end

    def icon
      chosen_icon || default_icon
    end

    # "default" (from the icon menu) or an empty value clears the choice.
    def icon=(value)
      super(value == "default" ? nil : value.presence)
    end

    # The admin's choice, nil for the default.
    def chosen_icon
      self[:settings].to_h["icon"].presence
    end

    def default_icon
      chat? ? "comment-discussion" : "light-bulb"
    end

    def default_label
      I18n.t("ai_assistance.skills.#{variant}.label")
    end

    # Offered in the menu: every skill needs its instructions, an LLM connection and a model.
    def ready?
      return false if skill_type.nil? || prompt.blank?
      return false unless assistant.usable?

      assistant.llm_resolution.ready?
    end

    # The action keys this skill may propose: none when read-only, a comment when
    # comment-only, otherwise what its type supports and a comment.
    def changeable_attributes
      return [] if skill_type.nil? || scope_read_only?
      return %w[comment] if scope_comment_only?

      skill_type.changeable_attributes + %w[comment]
    end

    # The admin's label or description, else the text of the skill's variant.
    def display_label
      label.presence || default_label
    end

    # "OP assistant · Refresh work package": the title of its dialogs and history entries.
    def full_label
      "#{assistant.name} · #{display_label}"
    end

    def display_description
      description.presence || I18n.t("ai_assistance.skills.#{variant}.description")
    end

    # The system prompt for a run, or nil when the skill has no prompt: the assistant's
    # instructions, the skill's prompt, and the output rules that the code owns.
    def system_prompt(locale:, tools: use_tools, work_package: true)
      full_system_prompt(locale:, tools:, work_package:) if prompt.present?
    end

    # Also without a prompt, to show on the skill page.
    def full_system_prompt(locale:, tools: use_tools, work_package: true)
      [assistant&.instructions, prompt, AI::Assistance::OutputRules.new(self, locale:, tools:, work_package:).to_s]
        .compact_blank.join("\n\n")
    end

    private

    # A deleted type, status, project or role would match nothing, and a list of only
    # deleted ids would hide the skill everywhere.
    def drop_deleted_condition_ids
      self.conditions = conditions.to_h { |key, ids| [key, CONDITION_MODELS.fetch(key).where(id: ids).pluck(:id)] }
    end

    # The block gives the work package's ids for the key; it runs only for a set condition.
    def role_matches?(project, user)
      condition_matches?(:role_ids) { user.roles_for_project(project).map(&:id) }
    end

    def drop_work_package_conditions
      self.conditions = conditions.to_h.except(*WORK_PACKAGE_CONDITIONS)
    end

    def condition_matches?(key)
      condition_ids(key).empty? || condition_ids(key).intersect?(yield)
    end
  end
end
