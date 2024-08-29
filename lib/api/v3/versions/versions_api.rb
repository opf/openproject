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

module API
  module V3
    module Versions
      class VersionsAPI < ::API::OpenProjectAPI
        resources :versions do
          get &::API::V3::Utilities::Endpoints::Index.new(model: Version,
                                                          scope: -> {
                                                            # the distinct(false) is added in order to allow ORDER BY LOWER(name)
                                                            # which would otherwise be invalid in postgresql
                                                            # SELECT DISTINCT, ORDER BY expressions must appear in select list
                                                            Version.visible(current_user).distinct(false)
                                                          })
                                                     .mount

          post &::API::V3::Utilities::Endpoints::Create.new(model: Version).mount

          mount ::API::V3::Versions::AvailableProjectsAPI
          mount ::API::V3::Versions::Schemas::VersionSchemaAPI
          mount ::API::V3::Versions::CreateFormAPI

          route_param :id, type: Integer, desc: "Version ID" do
            after_validation do
              @version = Version.find(params[:id])

              authorized_for_version?(@version)
            end

            helpers do
              def authorized_for_version?(version)
                projects = version.projects

                permissions = %i(view_work_packages manage_versions)

                authorize_in_projects(permissions, projects:) do
                  raise ::API::Errors::NotFound.new
                end
              end
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: Version).mount
            patch &::API::V3::Utilities::Endpoints::Update.new(model: Version).mount
            delete &::API::V3::Utilities::Endpoints::Delete.new(model: Version).mount

            mount ::API::V3::Versions::UpdateFormAPI
            mount ::API::V3::Versions::ProjectsByVersionAPI
          end
        end
      end
    end
  end
end
