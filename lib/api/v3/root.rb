#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# Root class of the API v3
# This is the place for all API v3 wide configuration, helper methods, exceptions
# rescuing, mounting of differnet API versions etc.

module API
  module V3
    class Root < ::API::OpenProjectAPI
      mount ::API::V3::Activities::ActivitiesAPI
      mount ::API::V3::Attachments::AttachmentsAPI
      mount ::API::V3::Categories::CategoriesAPI
      mount ::API::V3::Configuration::ConfigurationAPI
      mount ::API::V3::CustomOptions::CustomOptionsAPI
      mount ::API::V3::HelpTexts::HelpTextsAPI
      mount ::API::V3::Principals::PrincipalsAPI
      mount ::API::V3::Priorities::PrioritiesAPI
      mount ::API::V3::Projects::ProjectsAPI
      mount ::API::V3::Queries::QueriesAPI
      mount ::API::V3::Render::RenderAPI
      mount ::API::V3::Relations::RelationsAPI
      mount ::API::V3::Repositories::RevisionsAPI
      mount ::API::V3::Roles::RolesAPI
      mount ::API::V3::Statuses::StatusesAPI
      mount ::API::V3::StringObjects::StringObjectsAPI
      mount ::API::V3::Types::TypesAPI
      mount ::API::V3::Users::UsersAPI
      mount ::API::V3::UserPreferences::UserPreferencesAPI
      mount ::API::V3::Versions::VersionsAPI
      mount ::API::V3::WorkPackages::WorkPackagesAPI

      get '/' do
        RootRepresenter.new({}, current_user: current_user)
      end
    end
  end
end
