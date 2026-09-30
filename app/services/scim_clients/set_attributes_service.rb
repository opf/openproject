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

module ScimClients
  class SetAttributesService < BaseServices::SetAttributes
    private

    def set_attributes(params)
      super(params.except(:jwt_sub))
      update_service_account
    end

    def update_service_account
      service_account.assign_attributes(params.slice(:name))

      if model.authentication_method_sso?
        auth_provider_link.assign_attributes(params.slice(:auth_provider_id))
        auth_provider_link.external_id = params[:jwt_sub] if params.key?(:jwt_sub)
      end
    end

    def service_account
      model.service_account || model.build_service_account(admin: true)
    end

    def auth_provider_link
      @auth_provider_link ||= model.auth_provider_link || service_account.user_auth_provider_links.build
    end
  end
end
