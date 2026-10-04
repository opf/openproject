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

module Admin
  class ScimClientStaticTokensController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    def create
      scim_client = ScimClient.find(params[:scim_client_id])
      result = ::ScimClients::GenerateStaticTokenService.new(scim_client).call

      update_via_turbo_stream(component: Admin::ScimClients::TokenListComponent.new(scim_client))

      respond_with_dialog ScimClients::CreatedTokenDialogComponent.new(result.result)
    end

    def deletion_dialog
      respond_with_dialog ScimClients::RevokeStaticTokenDialogComponent.new(
        Doorkeeper::AccessToken.find(params[:id]),
        scim_client_id: params[:scim_client_id],
        turbo_frame: params[:target].presence
      )
    end

    def destroy
      token = Doorkeeper::AccessToken.find(params[:id])
      scim_client = ScimClient.find(params[:scim_client_id])

      ::ScimClients::RevokeStaticTokenService.new(scim_client).call(token)

      redirect_to edit_admin_scim_client_path(scim_client)
    end
  end
end
