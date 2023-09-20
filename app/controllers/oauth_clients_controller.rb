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

# This controller handles OAuth2 Authorization Code Grant redirects from a Authorization Server to
# "callback" endpoint.
class OAuthClientsController < ApplicationController
  before_action :set_oauth_state
  before_action :find_oauth_client
  before_action :set_redirect_uri
  before_action :set_code
  before_action :set_connection_manager

  after_action :clear_oauth_state_cookie

  # Provide the OAuth2 "callback" endpoint.
  # The Authorization Server redirects
  # here after successful authentication and authorization.
  # This endpoint gets a "code" parameter that cryptographically
  # contains a grant.
  # We get here by a URL like this:
  # http://localhost:4200/oauth_clients/asdf12341234qsdfasdfasdf/callback?
  #   state=http%3A%2F%2Flocalhost%3A4200%2Fprojects%2Fdemo-project%2Foauth2_example&
  #   code=MQoOnUTJGFdAo5jBGD1SqnDH0PV6yioG7NoYM2zZZlK3g6LuKrGUmOxjIS1bIy7fHEfZy2WrgYcx
  def callback
    # Exchange the code with a token using a HTTP call to the Authorization Server
    service_result = @connection_manager.code_to_token(@code)

    if service_result.success?
      # Redirect the user to the page that initially wanted to access the OAuth2 resource.
      # "state" is a nonce that identifies a cookie which holds that page's URL.
      redirect_to @redirect_uri
    else
      # We got a list of errors from ::OAuthClients::ConnectionManager
      set_oauth_errors(service_result)

      redirect_user_or_admin(@redirect_uri) do
        # If the current user is an admin, we send her directly to the
        # settings that she needs to edit.
        redirect_to edit_admin_settings_storage_path(@oauth_client.integration)
      end
    end
  end

  private

  def set_oauth_state
    @oauth_state = params[:state]
  end

  def clear_oauth_state_cookie
    cookies.delete("oauth_state_#{@oauth_state}") unless @oauth_state.nil?
  end

  def set_oauth_errors(service_result)
    flash[:error] = ["#{t(:'oauth_client.errors.oauth_authorization_code_grant_had_errors')}:"]
    service_result.errors.each do |error|
      flash[:error] << "#{t(:'oauth_client.errors.oauth_reported')}: #{error.full_message}"
    end
  end

  def set_code
    # The OAuth2 provider should have sent a code when using response_type = "code"
    # So this could either be an error from the Authorization Server (i.e. Nextcloud) or
    # ::OAuthClient::ConnectionManager has used the wrong response_type.
    @code = params[:code]

    if @code.blank?
      flash[:error] = [I18n.t('oauth_client.errors.oauth_code_not_present'),
                       I18n.t('oauth_client.errors.oauth_code_not_present_explanation')]

      redirect_user_or_admin(get_redirect_uri) do
        # If the current user is an admin, we send her directly to the
        # settings that she needs to edit/fix.
        redirect_to edit_admin_settings_storage_path(@oauth_client.integration)
      end
    end
  end

  def set_redirect_uri
    # redirect_uri is used by OpenProject to redirect to
    # after receiving an OAuth2 access token. So it should not be blank.
    service_result = ::OAuthClients::RedirectUriFromStateService
                       .new(state: @oauth_state, cookies:)
                       .call

    if service_result.success?
      @redirect_uri = service_result.result
    else
      # To protect against CSRF we cancel this request. There was either no
      # state parameter given, or there was no corresponding cookie present.
      flash[:error] = [I18n.t('oauth_client.errors.oauth_state_not_present'),
                       I18n.t('oauth_client.errors.oauth_state_not_present_explanation')]

      redirect_user_or_admin(nil) do
        # Guide the user to the settings that she needs to edit/fix.
        redirect_to edit_admin_settings_storage_path(@oauth_client.integration)
      end
    end
  end

  def set_connection_manager
    @connection_manager = OAuthClients::ConnectionManager.new(
      user: User.current,
      configuration: @oauth_client.integration.oauth_configuration
    )
  end

  def find_oauth_client
    @oauth_client = OAuthClient.find_by(client_id: params[:oauth_client_id])
    if @oauth_client.nil?
      # oauth_client can be nil if OAuthClient was not found.
      # This happens during admin setup if the user forgot to update the return_uri
      # on the Authorization Server (i.e. Nextcloud) after updating the OpenProject
      # side with a new client_id and client_secret.
      flash[:error] = [I18n.t('oauth_client.errors.oauth_client_not_found'),
                       I18n.t('oauth_client.errors.oauth_client_not_found_explanation')]

      redirect_user_or_admin(get_redirect_uri) do
        # Something must be wrong in the storage's setup
        redirect_to admin_settings_storages_path
      end
    end
  end

  def redirect_user_or_admin(redirect_uri = nil)
    # This needs to be modified as soon as we support more integration types.
    if User.current.admin && redirect_uri && (nextcloud? || one_drive?)
      yield
    elsif redirect_uri
      flash[:error] = [t(:'oauth_client.errors.oauth_issue_contact_admin')]
      redirect_to redirect_uri
    else
      redirect_to ::API::V3::Utilities::PathHelper::ApiV3Path::root_url
    end
  end

  def nextcloud?
    @oauth_client&.integration&.provider_type == ::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD
  end

  def one_drive?
    @oauth_client&.integration&.provider_type == ::Storages::Storage::PROVIDER_TYPE_ONE_DRIVE
  end

  def get_redirect_uri
    ::OAuthClients::RedirectUriFromStateService
      .new(state: @oauth_state, cookies:)
      .call
      .result
  end
end
