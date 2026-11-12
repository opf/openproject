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
  class ScimClientsController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    menu_item :scim_clients

    layout "admin"

    def index
      @scim_clients = ScimClient.order(:name)
    end

    def new
      @scim_client = ScimClient.new(authentication_method: :oauth2_token)
    end

    def edit
      @scim_client = ScimClient.find(params[:id])

      first_time_setup(@scim_client)
    end

    def create
      result = ::ScimClients::CreateService.new(user: User.current).call(scim_client_params)
      result.on_failure do
        @scim_client = result.result
        stream_form_component do |format|
          format.html { render :new }
        end
      end

      result.on_success do
        flash[:notice] = t(:notice_successful_create)
        store_oauth_secret(result.result)
        redirect_to(edit_admin_scim_client_path(result.result, first_time_setup: true))
      end
    end

    def update
      @scim_client = ScimClient.find(params[:id])
      result = ::ScimClients::UpdateService.new(user: User.current, model: @scim_client).call(scim_client_params)

      result.on_failure do
        stream_form_component do |format|
          format.html { render :edit }
        end
      end

      result.on_success do
        flash[:notice] = t(:notice_successful_update)
        redirect_to action: :index
      end
    end

    def deletion_dialog
      respond_with_dialog ScimClients::DeleteScimClientDialogComponent.new(ScimClient.find(params[:id]))
    end

    def destroy
      model = ScimClient.find(params[:id])
      result = ::ScimClients::DeleteService.new(user: User.current, model:).call

      if result.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = result.errors.full_messages
      end

      redirect_to action: :index
    end

    private

    def scim_client_params
      params.expect(scim_client: %i[name auth_provider_id authentication_method jwt_sub])
    end

    def first_time_setup(scim_client)
      return if params[:first_time_setup].blank?

      case scim_client.authentication_method
      when "oauth2_token"
        if scim_client.access_tokens.empty?
          @setup_token = ::ScimClients::GenerateStaticTokenService.new(scim_client).call.result
        end
      when "oauth2_client"
        key = oauth_secret_session_key(scim_client)
        if session.key?(key)
          @setup_client_secret = session.delete(key)
        end
      end
    end

    def stream_form_component(&)
      update_via_turbo_stream(component: Admin::ScimClients::FormComponent.new(@scim_client))
      respond_with_turbo_streams(&)
    end

    # saves plaintext oauth client secret to the session temporary
    # why?
    # because plaintext client secret needs to be presented to an admin in UI
    # and it is only present in memory just after oauth_application creation.
    # so, to be able to render it after redirection it is stored in the admin session
    # and then removed right after being rendered.
    def store_oauth_secret(scim_client)
      return unless scim_client.authentication_method_oauth2_client?

      plaintext_secret = scim_client.oauth_application.plaintext_secret
      session[oauth_secret_session_key(scim_client)] = plaintext_secret
    end

    def oauth_secret_session_key(scim_client)
      "scim-client-#{scim_client.id}-oauth-secret"
    end
  end
end
