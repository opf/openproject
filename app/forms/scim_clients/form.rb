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

module ScimClients
  class Form < ApplicationForm
    include Redmine::I18n

    form do |client_form|
      client_form.text_field(
        name: :name,
        label: ScimClient.human_attribute_name(:name),
        required: true,
        caption: I18n.t("admin.scim_clients.form.name_description"),
        input_width: :large
      )

      client_form.select_list(
        name: :auth_provider_id,
        label: ScimClient.human_attribute_name(:auth_provider_id),
        caption: I18n.t("admin.scim_clients.form.auth_provider_description"),
        input_width: :large,
        include_blank: false
      ) do |select|
        AuthProvider.find_each do |provider|
          select.option(
            value: provider.id,
            label: provider.display_name
          )
        end
      end

      client_form.select_list(
        name: :authentication_method,
        label: ScimClient.human_attribute_name(:authentication_method),
        caption: helpers.t("admin.scim_clients.form.authentication_method_description_html"),
        input_width: :large,
        include_blank: false,
        disabled: model.persisted?,
        data: {
          action: "scim-clients--form-inputs#updateFormInputs",
          "scim-clients--form-inputs-target": "authenticationMethodInput"
        }
      ) do |select|
        ScimClient.authentication_methods.each_key do |method|
          select.option(
            value: method,
            label: I18n.t("admin.scim_clients.authentication_methods.#{method}")
          )
        end
      end

      client_form.group(data: { "scim-clients--form-inputs-target": "jwtSubInputWrapper" }) do |group|
        group.text_field(
          name: :jwt_sub,
          label: ScimClient.human_attribute_name(:jwt_sub),
          required: true,
          caption: link_translate("admin.scim_clients.form.jwt_sub_description",
                                  links: { docs_url: %i[sysadmin_docs scim_jwt_authetication_method] },
                                  external: true),
          input_width: :large
        )
      end

      if show_client_id?
        client_form.html_content do
          render(Admin::ScimClients::ClientIdComponent.new(model))
        end
      end

      client_form.submit(
        name: :submit,
        label: model.persisted? ? I18n.t(:button_save) : I18n.t(:button_create),
        scheme: :primary,
        data: { "scim-clients--form-inputs-target": "submitButton" }
      )
    end

    def show_client_id?
      model.persisted? && model.authentication_method_oauth2_client?
    end
  end
end
