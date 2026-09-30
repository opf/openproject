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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  # See also: create_service.rb for comments
  module Storages
    class UpdateService < ::BaseServices::Update
      protected

      def after_validate(service_call)
        return handle_sharepoint_storage(service_call) if model.is_a? SharepointStorage

        service_call
      end

      # rubocop:disable Metrics/AbcSize
      def handle_sharepoint_storage(service_call)
        return service_call unless model.automatically_managed? && model.automatically_managed_changed?

        list_result = Adapters::Providers::Sharepoint::Services::CreateManagedListService.new(model).call

        if list_result.success?
          model.managed_drive_id = list_result.result.id
          model.managed_drive_name = list_result.result.name
        else
          service_call.errors = list_result.errors
          service_call.success = false
        end
        service_call
      end
      # rubocop:enable Metrics/AbcSize

      def after_perform(service_call)
        storage = service_call.result
        return service_call unless storage.provider_type_nextcloud?
        return service_call unless storage.oauth_application

        persist_service_result = ::OAuth::Applications::UpdateService
                                 .new(model: storage.oauth_application, user:)
                                 .call(
                                   name: "#{storage.name} (#{I18n.t("storages.provider_types.#{storage}.name")})",
                                   redirect_uri: File.join(storage.host, "index.php/apps/integration_openproject/oauth-redirect")
                                 )
        service_call.add_dependent!(persist_service_result)

        service_call
      end
    end
  end
end
