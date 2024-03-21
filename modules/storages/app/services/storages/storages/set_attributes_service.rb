#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    end

    private

    def set_attributes(params)
      super(replace_empty_host_with_nil(params))
      unset_nextcloud_application_credentials if nextcloud_storage?
    end

    def remove_host_trailing_slashes
      storage.host = storage.host&.gsub(/\/+$/, "")
    end

    def replace_empty_host_with_nil(params)
      cloned_param = params.clone

      if cloned_param[:host] == ""
        cloned_param[:host] = nil
      end

      cloned_param
    end

    def unset_nextcloud_application_credentials
      # Do not overwrite if has never been set.
      # E.g. when setting up a new storage for the first time, passthrough, credentials are set in a later stage.
      return if storage.automatic_management_unspecified?

      unless storage.automatic_management_enabled?
        %w[username password].each { |field| storage.provider_fields.delete(field) }
      end
    end

    def storage
      model
    end

    def nextcloud_storage?
      storage.is_a?(Storages::NextcloudStorage)
    end
  end
end
