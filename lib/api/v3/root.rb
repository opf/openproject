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

# Root class of the API v3
# This is the place for all API v3 wide configuration, helper methods, exceptions
# rescuing, mounting of different API versions etc.

module API
  module V3
    class Root < ::API::OpenProjectAPI
      helpers ::API::V3::Utilities::EpropsConversion

      before do
        # Add Link header for openapi spec
        header "Link", '</api/v3/openapi.json>; rel="service-desc"'

        # All endpoint accept query props as gzipped and base64 encoded json objects
        transform_eprops
      end

      mount ::API::V3::Actions::ActionsAPI
      mount ::API::V3::Activities::ActivitiesAPI
      mount ::API::V3::Attachments::AttachmentsAPI
      mount ::API::V3::Capabilities::CapabilitiesAPI
      mount ::API::V3::Backups::BackupsAPI
      mount ::API::V3::Categories::CategoriesAPI
      mount ::API::V3::Configuration::ConfigurationAPI
      mount ::API::V3::CustomActions::CustomActionsAPI
      mount ::API::V3::CustomOptions::CustomOptionsAPI
      mount ::API::V3::Days::DaysAPI
      mount ::API::V3::Grids::GridsAPI
      mount ::API::V3::Notifications::NotificationsAPI
      mount ::API::V3::HelpTexts::HelpTextsAPI
      mount ::API::V3::Memberships::MembershipsAPI
      mount ::API::V3::News::NewsAPI
      mount ::API::V3::OAuth::OAuthApplicationsAPI
      mount ::API::V3::OAuth::OAuthClientCredentialsAPI
      mount ::API::V3::Posts::PostsAPI
      mount ::API::V3::Principals::PrincipalsAPI
      mount ::API::V3::Priorities::PrioritiesAPI
      mount ::API::V3::Projects::ProjectsAPI
      mount ::API::V3::Projects::Statuses::StatusesAPI
      mount ::API::V3::Queries::QueriesAPI
      mount ::API::V3::Render::RenderAPI
      mount ::API::V3::Relations::RelationsAPI
      mount ::API::V3::Repositories::RevisionsAPI
      mount ::API::V3::Roles::RolesAPI
      mount ::API::V3::Shares::SharesAPI
      mount ::API::V3::Statuses::StatusesAPI
      mount ::API::V3::StringObjects::StringObjectsAPI
      mount ::API::V3::Types::TypesAPI
      mount ::API::V3::Users::UsersAPI
      mount ::API::V3::PlaceholderUsers::PlaceholderUsersAPI
      mount ::API::V3::UserPreferences::UserPreferencesAPI
      mount ::API::V3::Groups::GroupsAPI
      mount ::API::V3::Values::ValuesAPI
      mount ::API::V3::Versions::VersionsAPI
      mount ::API::V3::Views::ViewsAPI
      mount ::API::V3::WorkPackages::WorkPackagesAPI
      mount ::API::V3::WikiPages::WikiPagesAPI

      get "/" do
        RootRepresenter.new({}, current_user:)
      end

      get "/spec.json" do
        API::OpenAPI.spec
      end

      get "/openapi.json" do
        API::OpenAPI.spec
      end

      get "/spec.yml" do
        content_type "text/vnd.yaml"

        API::OpenAPI.spec.to_yaml
      end

      # Catch all unknown routes (therefore have it at the end of the file)
      # and return a properly formatted 404 error.
      route :any, "*path" do
        raise API::Errors::NotFound
      end
    end
  end
end
