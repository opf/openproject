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

# See also: create_service.rb for comments
module Storages::Storages
  class SetAttributesService < ::BaseServices::SetAttributes
    after_call :remove_host_trailing_slashes

    def set_default_attributes(_params)
      storage.creator ||= user
      storage.name ||= derive_default_storage_name
    end

    def set_default_provider_fields(_params)
      set_nextcloud_application_credentials_defaults if storage.provider_type_nextcloud?
    end

    private

    def set_attributes(params)
      super(params)
      set_default_provider_fields(params)
    end

    def remove_host_trailing_slashes
      storage.host = storage.host&.gsub(/\/+$/, '')
    end

    def set_nextcloud_application_credentials_defaults
      # Do not overwrite if has never been set.
      # E.g. when setting up a new storage for the first time, passthrough, credentials are set in a later stage.
      return if storage.automatic_management_unspecified?

      if storage.automatically_managed?
        storage.username = storage.provider_fields_defaults[:username]
      else
        storage.automatically_managed = false
        %w[username password].each { |field| storage.provider_fields.delete(field) }
      end
    end

    def storage
      model
    end

    def derive_default_storage_name
      prefix = I18n.t("storages.provider_types.#{storage.short_provider_type}.default_name")
      last_id = Storages::Storage.where("name like ?", "#{prefix}%").maximum(:id)

      return prefix if last_id.nil?

      "#{prefix} #{last_id + 1}"
    end
  end
end
