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
      if model.new_record?
        f.select_list(name: :skill_key, label: AI::AssistantSkill.human_attribute_name(:skill_key),
                      caption: I18n.t("admin.ai_assistants.skills.type_caption"),
                      include_blank: false, input_width: :large) do |select|
          AI::AssistantSkills::Registry.skills.each do |type|
            select.option(value: type.key, label: type_option_label(type))
          end
        end
      end

      f.text_field(name: :label, label: AI::AssistantSkill.human_attribute_name(:label), input_width: :large,
                   caption: I18n.t("admin.ai_assistants.skills.label_caption"),
                   placeholder: model.skill_type&.label)

      f.text_area(name: :description, label: AI::AssistantSkill.human_attribute_name(:description), rows: 2,
                  caption: I18n.t("admin.ai_assistants.skills.description_caption"),
                  placeholder: model.skill_type&.description)

      f.text_area(name: :prompt, label: AI::AssistantSkill.human_attribute_name(:prompt), rows: 14,
                  caption: I18n.t("admin.ai_assistants.skills.prompt_caption"))

      f.text_area(name: :output_rules, label: AI::AssistantSkill.human_attribute_name(:output_rules), rows: 10,
                  caption: I18n.t("admin.ai_assistants.skills.output_rules_caption"))

      f.text_field(name: :template_ref, label: AI::AssistantSkill.human_attribute_name(:template_ref),
                   input_width: :large, caption: I18n.t("admin.ai_assistants.skills.template_ref_caption"))

      if model.skill_type&.changeable_attributes.present?
        f.radio_button_group(name: :proposal_scope, label: AI::AssistantSkill.human_attribute_name(:proposal_scope)) do |group|
          AI::AssistantSkill.proposal_scopes.each_key do |value|
            group.radio_button(value:, label: I18n.t("admin.ai_assistants.skills.proposal_scopes.#{value}"),
                               caption: I18n.t("admin.ai_assistants.skills.proposal_scopes.#{value}_caption"))
          end
        end
      end

      f.check_box(name: :active, label: AI::AssistantSkill.human_attribute_name(:active))

      f.submit(name: :submit, label: model.persisted? ? I18n.t(:button_save) : I18n.t(:button_create),
               scheme: :primary)
    end

    private

    # "Preset" or "Chat"; with several types of one kind, the type's name is added.
    def type_option_label(type)
      same_kind = AI::AssistantSkills::Registry.skills.count { |other| other.kind == type.kind }
      same_kind > 1 ? "#{type.kind_label}: #{type.label}" : type.kind_label
    end
  end
end
