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

Rails.application.config.to_prepare do
  Scimitar.service_provider_configuration = Scimitar::ServiceProviderConfiguration.new(
    patch: Scimitar::Supportable.supported,
    authenticationSchemes: OpenProjectScimitar::AUTHENTICATION_SCHEMES
  )
  Scimitar.engine_configuration = Scimitar::EngineConfiguration.new(
    custom_authenticator: lambda do
      if !EnterpriseToken.allows_to?(:scim_api)
        plan = OpenProject::Token.lowest_plan_for(:scim_api)
        error = Scimitar::ErrorResponse.new(
          status: 403,
          detail: "This endpoint requires an enterprise subscription of at least #{plan}"
        )
        return handle_scim_error(error)
      end

      warden = request.env["warden"]
      user = warden.authenticate(scope: :scim_v2)
      if user.nil?
        if controller_path != "scimitar/service_provider_configurations" ||
           # It means authorization credentials were provided in ways expected by OpenProject, but the credentials were wrong.
           # So, no user found.
           warden.winning_strategy.present?
          throw(:warden)
        else
          limited_service_provider_configuration = {
            meta: Scimitar::Meta.new(
              resourceType: "ServiceProviderConfig",
              created: Time.zone.now,
              lastModified: Time.zone.now,
              version: "1"
            ),
            schemas: ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"],
            authenticationSchemes: OpenProjectScimitar::AUTHENTICATION_SCHEMES
          }
          render json: limited_service_provider_configuration
          return
        end
      else
        User.current = user
        # Only a ServiceAccount associated with a ScimClient can use SCIM Server API
        unless User.current.respond_to?(:service) && User.current.service.is_a?(ScimClient)
          return handle_scim_error(Scimitar::AuthenticationError.new)
        end
      end
      true
    end
  )

  Scimitar::Schema::User.singleton_class.class_eval do
    prepend OpenProjectScimitar::User
  end

  Scimitar::Schema::Group.singleton_class.class_eval do
    prepend OpenProjectScimitar::Group
  end
end
