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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

namespace = OpenProject::Authentication::Strategies::Warden

OpenProject::Authentication.add_strategy(:basic_auth_failure, namespace::BasicAuthFailure,  "Basic")
OpenProject::Authentication.add_strategy(:global_basic_auth,  namespace::GlobalBasicAuth,   "Basic")
OpenProject::Authentication.add_strategy(:user_basic_auth,    namespace::UserBasicAuth,     "Basic")
OpenProject::Authentication.add_strategy(:user_api_token,     namespace::UserAPIToken,      "Bearer")
OpenProject::Authentication.add_strategy(:oauth,              namespace::DoorkeeperOAuth,   "Bearer")
OpenProject::Authentication.add_strategy(:anonymous_fallback, namespace::AnonymousFallback, "Basic")
OpenProject::Authentication.add_strategy(:jwt_oidc,           namespace::JwtOidc,           "Bearer")
OpenProject::Authentication.add_strategy(:session,            namespace::Session,           "Session")

OpenProject::Authentication.update_strategies(OpenProject::Authentication::Scope::API_V3, { store: false }) do |_|
  %i[global_basic_auth
     user_basic_auth
     basic_auth_failure
     user_api_token
     oauth
     jwt_oidc
     session
     anonymous_fallback]
end

OpenProject::Authentication.update_strategies(OpenProject::Authentication::Scope::SCIM_V2, { store: false }) do |_|
  %i[oauth jwt_oidc]
end

OpenProject::Authentication.update_strategies(OpenProject::Authentication::Scope::MCP_SCOPE, { store: false }) do |_|
  %i[user_api_token oauth jwt_oidc user_basic_auth basic_auth_failure session]
end

Rails.application.configure do |app|
  app.config.middleware.use OpenProject::Authentication::Manager, intercept_401: false # rubocop:disable Naming/VariableNumber
end
