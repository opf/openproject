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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmModels
  class Form < ApplicationForm
    form do |f|
      # A discovered model is named by the server, so its identifier is not ours
      # to change -- the next refresh would only put it back. One entered by hand
      # is editable, because a typo in it is otherwise unfixable except by
      # deleting the model and losing everything asserted about it. Renaming
      # cascades; see LlmModel#cascade_rename!.
      if new_record? || model.manual?
        f.text_field(
          name: :external_id,
          label: LlmModel.human_attribute_name(:external_id),
          caption: I18n.t("admin.llm_models.form.external_id_caption"),
          placeholder: "qwen3.6-35b-a3b",
          required: true,
          autocomplete: "off",
          input_width: :large,
          data: { test_selector: "llm-model--external-id" }
        )
      end

      f.text_field(
        name: :display_name,
        label: LlmModel.human_attribute_name(:display_name),
        caption: I18n.t("admin.llm_models.form.display_name_caption"),
        autocomplete: "off",
        input_width: :large,
        data: { test_selector: "llm-model--display-name" }
      )

      f.text_field(
        name: :admin_context_window,
        label: I18n.t("admin.llm_models.form.context_window"),
        caption: context_window_caption,
        type: :number,
        min: 1,
        autocomplete: "off",
        input_width: :medium,
        data: { test_selector: "llm-model--context-window" }
      )

      Llm::Capabilities::ALL.each do |capability|
        f.select_list(
          name: :"capability_#{capability}",
          label: Llm::Capabilities.label(capability),
          caption: capability_caption(capability),
          include_blank: false,
          input_width: :medium,
          data: { test_selector: "llm-model--capability-#{capability}" }
        ) do |select|
          select.option(value: "", label: I18n.t("admin.llm_models.form.state_unspecified"))
          select.option(value: "supported", label: I18n.t("admin.llm_models.form.state_supported"))
          select.option(value: "unsupported", label: I18n.t("admin.llm_models.form.state_unsupported"))
        end
      end

      f.submit(
        name: :submit,
        label: new_record? ? I18n.t("admin.llm_models.form.create_submit") : I18n.t(:button_save),
        scheme: :primary,
        data: { test_selector: "llm-model--submit" }
      )
    end

    private

    def new_record? = model.new_record?

    def context_window_caption
      source = model.context_window_source

      if source.present? && source != :admin
        I18n.t("admin.llm_models.form.context_window_known",
               value: model.context_window,
               source: I18n.t("llm.context_window_sources.#{source}"))
      else
        I18n.t("admin.llm_models.form.context_window_caption")
      end
    end

    # A verdict established by a probe or a registry is reported rather than
    # loaded into the field, so saving the form does not silently turn someone
    # else's finding into the administrator's assertion.
    def capability_caption(capability)
      verdict = model.verdict_for(capability)
      return if verdict.nil? || verdict.source_admin?

      I18n.t("admin.llm_models.form.current_verdict",
             state: I18n.t("llm.verdict_states.#{verdict.state}"),
             source: I18n.t("llm.verdict_sources.#{verdict.source}"))
    end
  end
end
