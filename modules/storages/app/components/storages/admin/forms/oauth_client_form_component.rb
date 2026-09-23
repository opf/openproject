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
#
module Storages::Admin::Forms
  class OAuthClientFormComponent < StorageFormComponent
    def self.wrapper_key = :storage_oauth_client_section

    def form_url
      query = { continue_wizard: storage.id } if in_wizard
      admin_settings_storage_oauth_client_path(storage, query)
    end

    def form_method
      options[:form_method] || default_form_method
    end

    def cancel_button_path
      storage.persisted? ? edit_admin_settings_storage_path(storage) : admin_settings_storages_path
    end

    def storage_provider_credentials_instructions
      helpers.link_translate(
        "storages.instructions.#{storage}.oauth_configuration_html",
        links: { application_link: oauth_application_link }
      )
    end

    private

    def oauth_client
      options[:oauth_client] || storage.oauth_client
    end

    def oauth_application_link
      if storage.provider_type_nextcloud?
        Storages::UrlBuilder.url(storage.uri, "settings/admin/openproject")
      else
        [:storage_docs, :"#{storage}_oauth_application"]
      end
    end

    def first_time_configuration?
      storage.oauth_client.blank? || storage.oauth_client.new_record?
    end

    def default_form_method
      first_time_configuration? ? :post : :patch
    end

    def data_attributes
      { turbo_frame: "page-content" }
    end
  end
end
