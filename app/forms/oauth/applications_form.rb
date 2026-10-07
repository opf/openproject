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

module OAuth
  class ApplicationsForm < ApplicationForm
    include Redmine::I18n

    form do |f|
      f.check_box(
        name: :enabled,
        label: Doorkeeper::Application.human_attribute_name(:enabled),
        caption: I18n.t("oauth.application.instructions.enabled")
      )

      f.text_field(
        name: :name,
        label: Doorkeeper::Application.human_attribute_name(:name),
        caption: I18n.t("oauth.application.instructions.name"),
        required: true
      )

      f.text_area(
        name: :redirect_uri,
        label: Doorkeeper::Application.human_attribute_name(:redirect_uri),
        caption: I18n.t("oauth.application.instructions.redirect_uri_html") + ::Doorkeeper.configuration.native_redirect_uri, # TODO: nicer!
        required: true
      )

      f.check_box(
        name: :confidential,
        label: Doorkeeper::Application.human_attribute_name(:confidential),
        caption: I18n.t("oauth.application.instructions.confidential"),
        required: true
      )

      f.check_box_group(
        name: :scopes,
        label: Doorkeeper::Application.human_attribute_name(:scopes),
        caption: I18n.t("oauth.application.instructions.scopes")
      ) do |group|
        Doorkeeper.configuration.scopes.each do |scope|
          checkbox_options = {
            name: :scopes,
            label: I18n.exists?(scope, scope: "oauth.scopes") ? "#{I18n.t(scope, scope: 'oauth.scopes')} (#{scope})" : scope,
            required: true,
            value: scope
          }
          checkbox_options[:caption] = I18n.t(scope, scope: "oauth.scopes.explanations_admin") if I18n.exists?(scope, scope: "oauth.scopes.explanations_admin")
          group.check_box(**checkbox_options)
        end
      end

      f.fieldset_group(
        title: I18n.t("oauth.application.client_credentials"),
        description: link_translate(
          "oauth.client_credentials_impersonation",
          links: {
            client_credentials: %i[client_credentials_code_flow],
            authorization_code: %i[oauth_authorization_code_flow]
          },
          external: true
        )
      ) do |cf|
        cf.autocompleter(
          name: :client_credentials_user_id,
          label: User.model_name.human,
          caption: I18n.t("oauth.application.instructions.client_credential_user_id"),
          visually_hide_label: true,
          autocomplete_options: {
            resource: "users",
            component: "opce-user-autocompleter",
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.users,
            searchKey: "any_name_attribute",
            multiple: false,
            inputName: "doorkeeper_application[client_credentials_user_id]"
          }
        )
      end

      f.submit(label: model.persisted? ? I18n.t(:button_save) : I18n.t(:button_create), name: :submit, scheme: :primary)
    end
  end
end
