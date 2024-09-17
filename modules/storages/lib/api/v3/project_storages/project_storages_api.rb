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

module API::V3::ProjectStorages
  class ProjectStoragesAPI < API::OpenProjectAPI
    helpers Storages::Peripherals::Scopes

    resources :project_storages do
      get do
        query = ParamsToQueryService
                  .new(Storages::ProjectStorage,
                       current_user,
                       query_class: Queries::Storages::ProjectStorages::ProjectStoragesQuery)
                  .call(params)

        unless query.valid?
          message = I18n.t("api_v3.errors.missing_or_malformed_parameter", parameter: "filters")
          raise ::API::Errors::InvalidQuery.new(message)
        end

        results = query.results.filter { |result| current_user.allowed_in_project?(:view_file_links, result.project) }

        ::API::V3::ProjectStorages::ProjectStorageCollectionRepresenter.new(
          results,
          self_link: api_v3_paths.project_storages,
          query: API::Decorators::QueryParamsRepresenter.new(query).to_h,
          current_user:
        )
      end

      route_param :id, type: Integer, desc: "ProjectStorage id" do
        after_validation do
          @project_storage = Storages::ProjectStorage.find(params[:id])

          unless current_user.allowed_in_project?(:view_file_links, @project_storage.project)
            raise ::API::Errors::NotFound.new
          end
        end

        get &API::V3::Utilities::Endpoints::Show.new(model: Storages::ProjectStorage).mount

        mount API::V3::ProjectStorages::ProjectStorageOpenAPI
      end
    end
  end
end
