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
        disabled: read_only?,
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
          disabled: read_only?,
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
          input_width: :large,
          disabled: read_only?
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
            disabled: read_only?,
            data: { "admin--llm-connection-form-target": "secretInput" }
          )

          if model.api_key_stored? && !read_only?
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

      unless read_only?
        f.submit(
          name: :submit,
          label: submit_label,
          scheme: :primary,
          data: { "admin--llm-connection-form-target": "submitButton" }
        )
      end
    end

    private

    def read_only?
      model.configured_from_env?
    end

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
