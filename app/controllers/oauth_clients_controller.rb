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
    # Extract the cryptographic "code" that indicates that the user
    # has successfully authenticated agains the OAuth2 provider and has
    # provided authorization to access his resources.
    code = params[:code]
    if code.nil?
      # We should have gotten a code as a URL parameter after a redirect from Nextcloud.
      # ToDo:
      raise "OAuthClientsController.callback: Expected a 'code' parameter"
    end

    # Start the OAuth2 manager that will handle all the rest
    connection_manager = OAuthClients::ConnectionManager.new(User.current)

    # Exchange the code with a token using a HTTP call to the OAuth2 provider
    user_token = connection_manager.code_to_token(@oauth_client, code)

    # Redirect the user to the page that initially wanted to access the OAuth2 resource.
    # "state" is a variable that encapsulates the page's URL and status.
    redirect_uri = connection_manager.callback_page_redirect_uri(user_token, params[:state])
    redirect_to redirect_uri
  end

  private

  # Storage ID coming from routes.rb preparsed
  def find_oauth_client
    @oauth_client = OAuthClient.find(params[:id])
  end
end
