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

# See also: create_service.rb for comments
module Storages::Storages
  class UpdateService < ::BaseServices::Update
    protected

    def after_perform(service_call)
      super(service_call)

      storage = service_call.result
      if storage.provider_type_nextcloud?
        application = storage.oauth_application
        persist_service_result = ::OAuth::PersistApplicationService
         .new(application, user:)
         .call({
                 name: "#{storage.name} (#{I18n.t("storages.provider_types.#{storage.short_provider_type}.name")})",
                 redirect_uri: File.join(storage.host, "index.php/apps/integration_openproject/oauth-redirect")
               })
        service_call.add_dependent!(persist_service_result)
      end

      service_call
    end
  end
end
