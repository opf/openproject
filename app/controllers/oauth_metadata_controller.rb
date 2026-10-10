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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class OAuthMetadataController < ApplicationController
  no_authorization_required! :authorization_server, :protected_resource

  skip_before_action :check_if_login_required

  def authorization_server
    grant_types = Doorkeeper.configuration.grant_flows
    grant_types += ["refresh_token"] if Doorkeeper.configuration.refresh_token_enabled?
    render json: {
      issuer: local_issuer,
      authorization_endpoint: oauth_authorization_url,
      token_endpoint: oauth_token_url,
      introspection_endpoint: oauth_introspect_url,
      scopes_supported: supported_scopes,
      response_types_supported: response_types(Doorkeeper.configuration.grant_flows),
      grant_types_supported: grant_types,
      service_documentation: OpenProject::Static::Links.url_for(:oauth_applications)
    }
  end

  def protected_resource
    render json: {
      resource: resource_url,
      resource_name: Setting.app_title,
      authorization_servers:,
      scopes_supported: OpenProject::Authentication::Scope.values,
      bearer_methods_supported: ["header"],
      resource_documentation: OpenProject::Static::Links.url_for(:api_docs)
    }
  end

  private

  def supported_scopes
    Doorkeeper.configuration.scopes.to_a - OpenProject::Authentication.internal_oauth_scopes
  end

  def response_types(grant_types)
    grant_types.filter_map do |grant|
      case grant
      when "authorization_code"
        "code"
      when "implicit"
        "token"
      end
    end
  end

  def authorization_servers
    OpenIDConnect::Provider.where(available: true).map(&:issuer) + [local_issuer]
  end

  def instance_base_url
    "http#{'s' if request.ssl?}://#{Setting.host_name}"
  end

  alias resource_url instance_base_url

  alias local_issuer instance_base_url
end
