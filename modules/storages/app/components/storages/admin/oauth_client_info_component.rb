# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
module Storages::Admin
  class OAuthClientInfoComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include StorageViewInformation

    attr_reader :storage
    alias_method :oauth_client, :model

    def initialize(oauth_client:, storage:, **options)
      super(oauth_client, **options)
      @storage = storage
    end

    def edit_icon_button_options
      {
        icon: oauth_client_configured? ? :sync : :pencil,
        tag: :a,
        href: Rails.application.routes.url_helpers.new_admin_settings_storage_oauth_client_path(storage),
        scheme: :invisible,
        aria: { label: I18n.t("storages.label_edit_storage_oauth_client") },
        data: edit_icon_button_data_options,
        test_selector: 'storage-edit-oauth-client-button'
      }
    end

    private

    def edit_icon_button_data_options
      {}.tap do |data_h|
        data_h[:confirm] = I18n.t("storages.confirm_replace_oauth_client") if oauth_client_configured?
        data_h[:turbo_stream] = true
      end
    end

    def oauth_client_configured?
      storage.configuration_checks[:storage_oauth_client_configured]
    end
  end
end
