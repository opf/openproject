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

module Admin::Import::Jira
  class Form < ApplicationForm
    def credential_field(group, input_name:)
      if model.persisted? && model.public_send(input_name).present?
        group.html_content do
          render(Primer::BaseComponent.new(tag: :div, classes: "FormControl")) do
            render(
              Primer::OpenProject::FlexLayout.new(
                align_items: :flex_end,
                classes: "FormControl-input-wrap FormControl-input-width--large"
              )
            ) do |flex|
              flex.with_column(flex: 1) do
                render(
                  Primer::Alpha::TextField.new(
                    name: :"saved_#{input_name}",
                    label: I18n.t("admin.jira.form.fields.#{input_name}"),
                    input_width: :large,
                    disabled: true,
                    value: "*********"
                  )
                )
              end
              flex.with_column(ml: 2) do
                render(
                  Primer::Beta::IconButton.new(
                    icon: :trash,
                    scheme: :danger,
                    size: :medium,
                    tag: :a,
                    href: url_helpers.clear_credential_admin_import_jira_path(model, field: input_name),
                    "aria-label": I18n.t("admin.jira.form.button_delete_#{input_name}"),
                    data: {
                      "admin--jira-configuration-form-target": "button",
                      turbo_method: :delete,
                      turbo_confirm: I18n.t("admin.jira.form.delete_#{input_name}_confirm"),
                      action: "click->admin--jira-configuration-form#disableButtons"
                    }
                  )
                )
              end
            end
          end
        end

        group.text_field(
          name: input_name,
          label: I18n.t("admin.jira.form.fields.#{input_name}"),
          hidden: true,
          value: "",
          data: { "admin--jira-configuration-form-target": input_name.to_s.camelize(:lower) }
        )
      else
        group.text_field(
          name: input_name,
          label: I18n.t("admin.jira.form.fields.#{input_name}"),
          required: !model.persisted?,
          input_width: :large,
          autocomplete: "off",
          data: { "admin--jira-configuration-form-target": input_name.to_s.camelize(:lower) }
        )
      end
    end

    form do |f|
      f.text_field(
        name: :name,
        label: I18n.t("admin.jira.form.fields.name"),
        required: true,
        input_width: :medium
      )

      f.text_field(
        name: :url,
        label: I18n.t("admin.jira.form.fields.url"),
        required: true,
        input_width: :large,
        type: :url,
        data: { "admin--jira-configuration-form-target": "url" }
      )

      f.radio_button_group(
        name: :auth_method,
        data: {
          "admin--jira-configuration-form-target": "authMethodGroup"
        }
      ) do |group|
        group.radio_button(
          value: "bearer",
          label: "Personal access token (PAT)",
          caption: "We recommend using this authentication method.",
          data: {
            "show-when-value-selected-target": "cause",
            target_name: "auth_method"
          }
        )
        group.radio_button(
          value: "basic",
          label: "Basic auth",
          caption: "Use basic auth if you are using a Jira Server version 8 or the instance is configured behind a proxy.",
          data: {
            "show-when-value-selected-target": "cause",
            target_name: "auth_method"
          }
        )
      end

      f.group(
        hidden: !model.auth_method_bearer?,
        data: {
          "show-when-value-selected-target": "effect",
          target_name: "auth_method",
          value: "bearer"
        }
      ) do |bearer_group|
        credential_field(bearer_group, input_name: :personal_access_token)
      end

      f.group(
        hidden: !model.auth_method_basic?,
        data: {
          "show-when-value-selected-target": "effect",
          target_name: "auth_method",
          value: "basic"
        }
      ) do |basic_group|
        basic_group.text_field(
          name: :basic_auth_username,
          label: I18n.t("admin.jira.form.fields.basic_auth_username"),
          input_width: :large,
          required: !model.persisted?,
          data: { "admin--jira-configuration-form-target": "basicAuthUsername" }
        )
        credential_field(basic_group, input_name: :basic_auth_password)
      end

      f.group(layout: :horizontal, mt: 1, mb: 2) do |button_group|
        button_group.submit(
          name: :submit,
          label: model.persisted? ? I18n.t("admin.jira.form.button_save") : I18n.t("admin.jira.form.button_add"),
          scheme: :primary,
          data: { "admin--jira-configuration-form-target": "button" }
        )

        button_group.button(
          name: :cancel,
          label: I18n.t(:button_cancel),
          scheme: :default,
          tag: :a,
          href: url_helpers.admin_import_jira_index_path
        )

        button_group.button(
          name: :test_connection,
          label: "Test Connection",
          scheme: :default,
          href: url_helpers.admin_import_jira_index_path,
          data: { action: "click->admin--jira-configuration-form#testConnection" }
        )
      end
    end
  end
end
