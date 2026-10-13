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
  class AssistantSkillForm < ApplicationForm
    form do |f|
      f.fieldset_group(title: I18n.t("admin.ai_assistants.skills.sections.menu"),
                       description: I18n.t("admin.ai_assistants.skills.sections.menu_description")) do |g|
        if model.new_record?
          g.select_list(name: :skill_key, label: AI::AssistantSkill.human_attribute_name(:skill_key),
                        caption: I18n.t("admin.ai_assistants.skills.type_caption"),
                        include_blank: false, input_width: :large) do |select|
            AI::AssistantSkills::Registry.skills.each do |type|
              select.option(value: type.key, label: type_option_label(type))
            end
          end
        end

        g.text_field(name: :label, label: AI::AssistantSkill.human_attribute_name(:label), input_width: :large,
                     caption: I18n.t("admin.ai_assistants.skills.label_caption"),
                     placeholder: model.skill_type&.label)

        g.text_area(name: :description, label: AI::AssistantSkill.human_attribute_name(:description), rows: 2,
                    caption: I18n.t("admin.ai_assistants.skills.description_caption"),
                    placeholder: model.skill_type&.description)

        g.check_box(name: :active, label: AI::AssistantSkill.human_attribute_name(:active))
      end

      f.fieldset_group(title: I18n.t("admin.ai_assistants.skills.sections.instructions"), mt: 4) do |g|
        g.text_area(name: :prompt, label: AI::AssistantSkill.human_attribute_name(:prompt), rows: 8,
                    caption: I18n.t("admin.ai_assistants.skills.prompt_caption"))

        g.text_area(name: :output_rules, label: AI::AssistantSkill.human_attribute_name(:output_rules), rows: 5,
                    caption: I18n.t("admin.ai_assistants.skills.output_rules_caption"))

        if @admin
          g.text_field(name: :template_ref, label: AI::AssistantSkill.human_attribute_name(:template_ref),
                       input_width: :large, caption: I18n.t("admin.ai_assistants.skills.template_ref_caption"))
        end
      end

      if model.skill_type&.changeable_attributes.present?
        f.fieldset_group(title: AI::AssistantSkill.human_attribute_name(:proposal_scope), mt: 4) do |g|
          g.radio_button_group(name: :proposal_scope, label: AI::AssistantSkill.human_attribute_name(:proposal_scope),
                               visually_hide_label: true) do |group|
            AI::AssistantSkill.proposal_scopes.each_key do |value|
              group.radio_button(value:, label: I18n.t("admin.ai_assistants.skills.proposal_scopes.#{value}"),
                                 caption: I18n.t("admin.ai_assistants.skills.proposal_scopes.#{value}_caption"))
            end
          end
        end
      end

      f.fieldset_group(title: I18n.t("admin.ai_assistants.skills.sections.conditions"),
                       description: I18n.t("admin.ai_assistants.skills.conditions.caption"), mt: 4) do |g|
        g.group(layout: :horizontal) do |row|
          condition_input(row, :type_ids, Type.order(:position).pluck(:id, :name))
          condition_input(row, :status_ids, Status.order(:position).pluck(:id, :name))
        end
        g.group(layout: :horizontal) do |row|
          condition_input(row, :project_ids, condition_projects)
          condition_input(row, :role_ids, ProjectRole.givable.ordered_by_builtin_and_position.map { [it.id, it.name] }.uniq)
        end
      end

      f.submit(name: :submit, label: model.persisted? ? I18n.t(:button_save) : I18n.t(:button_create),
               scheme: :primary, mt: 4)
    end

    def initialize(admin: false)
      super()
      @admin = admin
    end

    private

    # A multi-select of ids. The hidden blank makes a cleared input clear the condition.
    def condition_input(form, key, choices)
      selected = model.condition_ids(key)
      name = "condition_#{key}"
      form.hidden(name: "#{name}[]", value: "", scope_name_to_model: false)
      form.autocompleter(name:, scope_name_to_model: false,
                         label: I18n.t("admin.ai_assistants.skills.conditions.#{key}"),
                         autocomplete_options: { multiple: true, decorated: true, clearable: true, focusDirectly: false,
                                                 inputName: name, inputValue: selected,
                                                 placeholder: I18n.t("admin.ai_assistants.skills.conditions.all") }) do |list|
        choices.each { |id, label| list.option(label:, value: id, selected: selected.include?(id)) }
      end
    end

    # The projects the user can see, and those already chosen.
    def condition_projects
      Project.visible(User.current).or(Project.where(id: model.condition_ids(:project_ids)))
             .order(:name).pluck(:id, :name)
    end

    # "Preset" or "Chat"; with several types of one kind, the type's name is added.
    def type_option_label(type)
      same_kind = AI::AssistantSkills::Registry.skills.count { |other| other.kind == type.kind }
      same_kind > 1 ? "#{type.kind_label}: #{type.label}" : type.kind_label
    end
  end
end
