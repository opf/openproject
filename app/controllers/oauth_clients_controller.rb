#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# This controller handles OAauth2 redirects from a provider to
# "callback" page.
class OAuthClientsController < ApplicationController
  before_action :find_oauth_client

  # Provide the OAuth2 "callback" page:
  # The OAuthClientsManager.get_token() method redirects
  # here after successful authentication and authorization.
  # This page gets a "code" parameter that cryptographically
  # contains the approval.
  # We get here by a URL like this:
  # http://localhost:4200/oauth_client/1/oauth_callback?
  #   state=http%3A%2F%2Flocalhost%3A4200%2Fprojects%2Fdemo-project%2Foauth2_example&
  #   code=MQoOnUTJGFdAo5jBGD1SqnDH0PV6yioG7NoYM2zZZlK3g6LuKrGUmOxjIS1bIy7fHEfZy2WrgYcx
  def callback
    # oauth_client can be nil if OAuthClient was not found.
    # This happens during admin setup if the user forgot to update the return_uri
    # on Nextcloud after updating the OpenProject side with a new client_id and client_secret.
    if !@oauth_client
      flash[:error] = [I18n.t('oauth_client.errors.oauth_client_not_found'),
                       I18n.t('oauth_client.errors.oauth_client_not_found_explanation')]
      redirect_to admin_settings_storages_path # Redirect to admin, because this only happens to sloppy admins
      return
    end

    # Extract the cryptographic "code" that indicates that the user
    # has successfully authenticated agains the OAuth2 provider and has
    # provided authorization to access his resources.
    code = params[:code]
    if code.blank?
      # The OAuth2 provider should have sent a code when using response_type = "code"
      # So this could either an error from the OAuth2 provider (Nextcloud) or
      # ConnectionManager has used the wrong response_type.
      flash[:error] = [I18n.t('oauth_client.errors.oauth_code_not_present'),
                       I18n.t('oauth_client.errors.oauth_code_not_present_explanation')]
      redirect_to admin_settings_storages_path # Redirect to admin, because this only happens to sloppy admins
      return
    end

    # state is used by OpenProject to contain the redirection URL where to
    # continue after receiving an OAuth2 token. So it should not be blank
    state = params[:state]
    if state.blank?
      flash[:error] = [I18n.t('oauth_client.errors.oauth_state_not_present'),
                       I18n.t('oauth_client.errors.oauth_state_not_present_explanation')]
      redirect_to admin_settings_storages_path # Redirect to admin, because this only happens to sloppy admins
      return
    end

    # Start the OAuth2 manager that will handle all the rest
    connection_manager = OAuthClients::ConnectionManager.new(user: User.current, oauth_client: @oauth_client)

    # Exchange the code with a token using a HTTP call to the OAuth2 provider
    service_result = connection_manager.code_to_token(code)
    if service_result.success?
      # Redirect the user to the page that initially wanted to access the OAuth2 resource.
      # "state" is a variable that encapsulates the page's URL and status.
      redirect_uri = connection_manager.callback_page_redirect_uri(params[:state])
      redirect_to redirect_uri
    else
      # We got a list of errors from ConnectionManger
      flash[:error] = ["#{t(:'oauth_client.errors.oauth_was_a_mess')}:"]
      service_result.errors.each do |error|
        flash[:error] << "#{t(:'oauth_client.errors.oauth_reported')}: #{error.full_message}"
      end

      redirect_user_or_admin(state)
    end
  end

  def refresh
    # Test page for refreshing OAuth2 token
    if !@oauth_client
      flash[:error] = [I18n.t('oauth_client.errors.oauth_client_not_found'),
                       I18n.t('oauth_client.errors.oauth_client_not_found_explanation')]
      redirect_to admin_settings_storages_path # Redirect to admin, because this only happens to sloppy admins
      return
    end

    # Start the OAuth2 manager that will handle all the rest
    connection_manager = OAuthClients::ConnectionManager.new(user: User.current, oauth_client: @oauth_client)
    connection_manager.refresh_token

    # ToDo: This redirect is only for admins
    redirect_to admin_settings_storages_path(@oauth_client.integration)
  end

  private

  def redirect_user_or_admin(state)
    if User.current.admin
      # ToDo: Check that integration a storage is
      redirect_to admin_settings_storages_path(@oauth_client.integration)
    else
      flash[:error] = [t(:'oauth_client.errors.oauth_issue_contact_admin')]
      redirect_to state
    end
  end

  # Storage ID coming from routes.rb preparsed
  # Returns nil in case thae OAuthClient is not found.
  # This can happen during setup if the user forgot to update
  # the ID in the return_uri on the Nextcloud side.
  def find_oauth_client
    # During development we need to be able to identify the oauth_client by it's ID
    @oauth_client = OAuthClient.find_by(id: params[:id])
    # Nextcloud "automaticial" configuration just adds the OAuth2 client_id as the Id
    # so the Nextcloud side doesn't need to know the OpenProject object ID.
    if @oauth_client.nil?
      @oauth_client = OAuthClient.find_by(client_id: params[:id])
    end
  end
end
