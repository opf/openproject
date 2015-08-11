#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/work_packages/work_package_representer'
require 'api/v3/work_packages/work_packages_shared_helpers'
require 'api/v3/work_packages/create_contract'

module API
  module V3
    module WorkPackages
      class WorkPackagesByProjectAPI < ::API::OpenProjectAPI
        resources :work_packages do
          helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers
          helpers do
            def create_service
              @create_service ||=
                CreateWorkPackageService.new(
                  user: current_user,
                  project: @project,
                  send_notifications: !(params.has_key?(:notify) && params[:notify] == 'false'))
            end

            def set_filters_from_json(query, json)
              filters = JSON.parse(json)
              operators = filters.inject({}) { |result, filter|
                attribute = filter.keys.first # there should only be one attribute per filter
                result[attribute] = filter[attribute]['operator']
                result
              }
              values = filters.inject({}) { |result, filter|
                attribute = filter.keys.first # there should only be one attribute per filter
                result[attribute] = filter[attribute]['values']
                result
              }

              query.filters = []
              query.add_filters(filters.map(&:keys).flatten, operators, values)
            end

            def collection_representer(work_packages, filter_json:)
              query = {}
              query[:filters] = filter_json if filter_json

              ::API::V3::WorkPackages::WorkPackageCollectionRepresenter.new(
                work_packages,
                api_v3_paths.work_packages_by_project(@project.id),
                query: query,
                page: params[:offset] ? params[:offset].to_i : nil,
                per_page: params[:pageSize] ? params[:pageSize].to_i : nil,
                context: {
                  current_user: current_user
                }
              )
            end
          end

          get do
            authorize(:view_work_packages, context: @project)

            query = Query.new({ name: '_', project: @project })
            set_filters_from_json(query, params[:filters]) if params[:filters]


            collection_representer(query.results.work_packages,
                                   filter_json: params[:filters])
          end

          post do
            work_package = create_service.create

            write_work_package_attributes work_package

            contract = ::API::V3::WorkPackages::CreateContract.new(work_package, current_user)
            if contract.validate && create_service.save(work_package)
              work_package.reload
              WorkPackages::WorkPackageRepresenter.create(work_package, current_user: current_user)
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(contract.errors)
            end
          end

          mount ::API::V3::WorkPackages::CreateFormAPI
        end
      end
    end
  end
end
