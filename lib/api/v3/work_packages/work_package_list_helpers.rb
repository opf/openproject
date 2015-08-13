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

module API
  module V3
    module WorkPackages
      module WorkPackageListHelpers
        extend Grape::API::Helpers

        def work_packages_by_params(project: nil)
          query = Query.new({ name: '_', project: project })
          set_filters_from_json(query, params[:filters]) if params[:filters]
          set_sorting_from_json(query, params[:sort_by]) if params[:sort_by]

          collection_representer(query.results.sorted_work_packages,
                                 project: project,
                                 filter_json: params[:filters],
                                 sort_json: params[:sort_by])
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

        def set_sorting_from_json(query, json)
          query.sort_criteria = JSON.parse(json)
        end

        def collection_representer(work_packages, project:, filter_json:, sort_json:)
          query = {}
          query[:filters] = filter_json if filter_json
          query[:sort_by] = sort_json if sort_json

          self_link = if project
                        api_v3_paths.work_packages_by_project(project.id)
                      else
                        api_v3_paths.work_packages
                      end

          ::API::V3::WorkPackages::WorkPackageCollectionRepresenter.new(
            work_packages,
            self_link,
            query: query,
            page: params[:offset] ? params[:offset].to_i : nil,
            per_page: params[:pageSize] ? params[:pageSize].to_i : nil,
            context: {
              current_user: current_user
            }
          )
        end
      end
    end
  end
end
