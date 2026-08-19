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

module WorkPackageTypes
  class SubjectConfigurationForm < ApplicationForm
    include Redmine::I18n

    form do |subject_form|
      subject_form.radio_button_group(name: :subject_configuration) do |group|
        group.radio_button(
          value: :manual,
          checked: subject_configuration_manual?,
          label: I18n.t("types.edit.subject_configuration.manually_editable_subjects.label"),
          caption: I18n.t("types.edit.subject_configuration.manually_editable_subjects.caption"),
          data: { action: "admin--subject-configuration#hidePatternInput" }
        )
        group.radio_button(
          value: :generated,
          checked: !subject_configuration_manual?,
          label: I18n.t("types.edit.subject_configuration.automatically_generated_subjects.label"),
          caption: I18n.t("types.edit.subject_configuration.automatically_generated_subjects.caption"),
          disabled: !enterprise?,
          data: { action: "admin--subject-configuration#showPatternInput" }
        )
      end

      subject_form.group(data: { "admin--subject-configuration-target": "patternInput" }) do |toggleable_group|
        toggleable_group.pattern_input(
          name: :pattern,
          value: model.pattern,
          disabled: !enterprise?,
          suggestions: model.suggestions,
          label: I18n.t("types.edit.subject_configuration.pattern.label"),
          caption: pattern_input_caption,
          required: true,
          validation_message: validation_message_for(:patterns)
        )
      end

      subject_form.submit(
        name: :submit,
        label: I18n.t(:button_save),
        scheme: :primary
      )
    end

    private

    def subject_configuration_manual?
      model.subject_configuration == :manual
    end

    def enterprise?
      EnterpriseToken.allows_to?(:work_package_subject_generation)
    end

    def validation_message_for(attribute)
      model.validation_errors.messages_for(attribute).to_sentence.presence
    end

    def pattern_input_caption
      link_translate("types.edit.subject_configuration.pattern.caption", links: {
                       attributes_url: %i[enterprise_features work_package_subject_generation]
                     })
    end
  end
end
