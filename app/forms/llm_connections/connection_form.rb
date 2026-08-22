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

module LlmConnections
  class ConnectionForm < ApplicationForm
    form do |f|
      f.check_box(
        name: :llm_features_enabled,
        label: LlmConnection.human_attribute_name(:llm_features_enabled),
        caption: I18n.t("admin.llm_connections.form.llm_features_enabled_caption"),
        data: { target_name: "llm_features_enabled", show_when_checked_target: "cause" }
      )

      f.fieldset_group(
        title: I18n.t("admin.llm_connections.form.server_group"),
        hidden: !model.llm_features_enabled,
        data: {
          target_name: "llm_features_enabled",
          show_when_checked_target: "effect",
          show_when: "checked"
        }
      ) do |fg|
        fg.html_content { server_descriptions }

        fg.select_list(
          name: :api_format,
          label: LlmConnection.human_attribute_name(:api_format),
          caption: I18n.t("admin.llm_connections.form.api_format_caption"),
          include_blank: false,
          input_width: :medium,
          data: { target_name: "llm_connection_api_format", show_when_value_selected_target: "cause" }
        ) do |select|
          supported_formats.each do |format|
            select.option(value: format, label: api_format_label(format))
          end
        end

        fg.text_field(
          name: :base_url,
          label: LlmConnection.human_attribute_name(:base_url),
          caption: I18n.t("admin.llm_connections.form.base_url_caption"),
          placeholder: "https://example.com/v1",
          required: true,
          type: :url,
          input_width: :large
        )

        fg.group(layout: :horizontal) do |row|
          row.text_field(
            name: :api_key,
            label: LlmConnection.human_attribute_name(:api_key),
            caption: api_key_caption,
            placeholder: api_key_placeholder,
            # The stored key is never sent to the browser, only a key typed into a
            # submission that failed. A blank submission means "keep the current
            # key", handled in the controller.
            value: model.api_key_changed? ? model.api_key : nil,
            type: :password,
            autocomplete: "off",
            input_width: :large,
            data: { "admin--llm-connection-form-target": "secretInput" }
          )

          if model.api_key_stored?
            row.button(
              name: :remove_api_key,
              tag: :a,
              label: I18n.t("admin.llm_connections.form.api_key_remove"),
              scheme: :danger,
              mt: 4,
              href: url_helpers.delete_api_key_dialog_llm_connection_path,
              data: { controller: "async-dialog" },
              test_selector: "llm-connection--remove-api-key"
            )
          end
        end
      end

      if models_available?
        # An autocompleter rather than a select: a gateway reports hundreds of
        # models, and every one of them would otherwise be inlined as an option
        # in the page body. decorated: true serialises the list into the element,
        # so this needs no endpoint of its own.
        f.autocompleter(
          name: :default_chat_model_id,
          label: LlmConnection.human_attribute_name(:default_chat_model_id),
          caption: I18n.t("admin.llm_connections.form.default_chat_model_caption"),
          autocomplete_options: {
            decorated: true,
            inputValue: model.default_chat_model_id,
            placeholder: I18n.t("label_none_parentheses")
          }
        ) do |list|
          list.option(label: I18n.t("label_none_parentheses"), value: "",
                      selected: model.default_chat_model_id.blank?)

          default_chat_model_options.each do |model_id|
            list.option(label: option_label(model_id), value: model_id,
                        selected: model.default_chat_model_id == model_id)
          end
        end
      end

      f.submit(
        name: :submit,
        label: submit_label,
        scheme: :primary,
        data: { "admin--llm-connection-form-target": "submitButton" }
      )
    end

    private

    # Only formats a request can actually be sent in. The contract rejects the
    # rest as a backstop, but they should not be offered in the first place.
    def supported_formats
      Llm::Adapters::FORMATS.select { |format| Llm::Session.supports?(format) }
    end

    def api_format_label(format)
      I18n.t("llm.api_formats.#{format}")
    end

    def server_descriptions
      helpers.safe_join(
        supported_formats.map do |format|
          render(
            Primer::Beta::Text.new(
              tag: :p,
              color: :muted,
              hidden: format != model.api_format,
              data: {
                target_name: "llm_connection_api_format",
                show_when_value_selected_target: "effect",
                value: format
              }
            )
          ) { I18n.t("admin.llm_connections.form.server_description", api_format: api_format_label(format)) }
        end
      )
    end

    def models_available?
      model.available_model_ids.any?
    end

    # Deactivated models are hidden, and so is anything positively known to be
    # an embedding model -- it is a different kind of model, not a chat choice.
    # The one already chosen is kept regardless: dropping it would silently
    # blank the field on the next save.
    def default_chat_model_options
      chat_capable = model.selectable_model_ids.reject { |id| embeddings_state(id) == :supported }

      (chat_capable + [model.default_chat_model_id]).compact_blank.uniq
    end

    # The same friendly name the model table shows; the identifier stays the value.
    def option_label(model_id)
      model_names[model_id].presence || model_id
    end

    def model_names
      @model_names ||= model.models.pluck(:external_id, :display_name).to_h
    end

    # No verdict at all is the same as an inconclusive one: we do not know.
    def embeddings_state(model_id)
      embeddings_verdicts[model_id]&.to_sym || :unknown
    end

    def embeddings_verdicts
      @embeddings_verdicts ||= model.capability_verdicts
                                    .for_capability(:embeddings)
                                    .pluck(:model_id, :state)
                                    .to_h
    end

    def submit_label
      model.persisted? ? I18n.t(:button_save) : I18n.t("admin.llm_connections.form.button_connect")
    end

    def api_key_caption
      I18n.t("admin.llm_connections.form.api_key_caption#{'_stored' if model.api_key_stored?}")
    end

    def api_key_placeholder
      I18n.t("admin.llm_connections.form.api_key_placeholder_stored") if model.api_key_stored?
    end
  end
end
