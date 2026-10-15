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
  class GeneralInfoFormComponent < StorageFormComponent
    def self.wrapper_key = :storage_general_info_section

    options submit_button_disabled: false

    def form_url
      query = { origin_component: "general_information" }
      query[:continue_wizard] = storage.id if in_wizard

      if storage.persisted?
        admin_settings_storage_path(storage, query)
      else
        admin_settings_storages_path(query)
      end
    end

    def submit_button_options
      { disabled: submit_button_disabled }
    end

    def cancel_button_options
      { href: cancel_button_path,
        data: { turbo_stream: true } }.tap do |options_hash|
        if storage.new_record?
          options_hash[:data][:turbo_stream] = false
          options_hash[:target] = "_top" # Break out of Turbo Frame, follow full page redirect
        end
      end
    end

    private

    def form_method
      if storage.persisted?
        :patch
      else
        :post
      end
    end

    def cancel_button_path
      options.fetch(:cancel_button_path) do
        if storage.persisted?
          edit_admin_settings_storage_path(storage)
        else
          admin_settings_storages_path
        end
      end
    end

    def provider_configuration_instructions
      helpers.link_translate(
        "storages.instructions.#{storage.short_provider_type}.provider_configuration_html",
        links: { application_link: [:storage_docs, :"#{storage.short_provider_type}_oauth_application"] }
      )
    end
  end
end
