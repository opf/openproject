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
        g.text_field(name: :label, label: AI::AssistantSkill.human_attribute_name(:label), input_width: :large,
                     caption: I18n.t("admin.ai_assistants.skills.label_caption"),
                     placeholder: model.default_label)

        g.text_area(name: :description, label: AI::AssistantSkill.human_attribute_name(:description), rows: 2,
                    caption: I18n.t("admin.ai_assistants.skills.description_caption"),
                    placeholder: model.display_description)

        g.check_box(name: :answers_at_once, label: AI::AssistantSkill.human_attribute_name(:answers_at_once),
                    caption: I18n.t("admin.ai_assistants.skills.answers_at_once_caption"))

        g.check_box(name: :active, label: AI::AssistantSkill.human_attribute_name(:active))
      end

      f.fieldset_group(title: I18n.t("admin.ai_assistants.skills.sections.instructions")) do |g|
        g.text_area(name: :prompt, label: AI::AssistantSkill.human_attribute_name(:prompt), rows: 8,
                    caption: I18n.t("admin.ai_assistants.skills.prompt_caption"),
                    data: { ai_assistance__prompt_preview_target: "source",
                            action: "input->ai-assistance--prompt-preview#update" })

        g.check_box(name: :use_tools, label: AI::AssistantSkill.human_attribute_name(:use_tools),
                    caption: I18n.t("admin.ai_assistants.skills.use_tools_caption"),
                    data: { target_name: "use_tools", show_when_checked_target: "cause" })

        g.html_content { prompt_preview }
      end

      if model.skill_type&.changeable_attributes.present?
        f.fieldset_group(title: AI::AssistantSkill.human_attribute_name(:proposal_scope)) do |g|
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
                       description: I18n.t("admin.ai_assistants.skills.conditions.caption")) do |g|
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
               scheme: :primary)
    end

    private

    # The full system prompt as it is sent, in the current locale. The skill prompt and the tool rule
    # follow the form fields before the skill is saved.
    def prompt_preview
      render(Primer::Beta::Details.new) do |details|
        details.with_summary(button: false) do
          render(Primer::Beta::Text.new(font_size: :small, color: :muted)) { I18n.t("admin.ai_assistants.skills.prompt_preview") }
        end
        details.with_body do
          render(Primer::Beta::Text.new(tag: :p, font_size: :small, color: :muted, mt: 1, mb: 0)) do
            I18n.t("admin.ai_assistants.skills.prompt_preview_caption")
          end +
          prompt_variant(tools: true) + prompt_variant(tools: false)
        end
      end
    end

    # One variant for each state of "Use OpenProject MCP tools"; the checkbox shows the matching one.
    def prompt_variant(tools:)
      render(Primer::Beta::Text.new(tag: :pre, font_size: :small, p: 2, mt: 1, bg: :subtle, border: true, border_radius: 2,
                                    style: "white-space: pre-wrap",
                                    classes: ("d-none" if model.use_tools != tools),
                                    data: { test_selector: "ai-skill-prompt-preview#{'-without-tools' unless tools}",
                                            target_name: "use_tools", show_when_checked_target: "effect",
                                            show_when: tools ? "checked" : "unchecked" })) do
        prompt_parts(tools:)
      end
    end

    # The parts of AI::AssistantSkill#full_system_prompt, with the skill prompt as its own element,
    # so ai-assistance--prompt-preview can replace it while the admin types.
    def prompt_parts(tools:)
      instructions = model.assistant&.instructions
      prompt = model.prompt.to_s

      helpers.safe_join([
        ("#{instructions}\n\n" if instructions.present?),
        preview_target("output", prompt),
        preview_target("separator", "\n\n", hidden: prompt.blank?),
        output_rules(tools:)
      ].compact)
    end

    def output_rules(tools:)
      AI::Assistance::OutputRules.new(model, locale: I18n.locale, tools:).to_s
    end

    def preview_target(name, text, **)
      helpers.content_tag(:span, text, data: { ai_assistance__prompt_preview_target: name }, **)
    end

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
  end
end
