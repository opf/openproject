#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Grids
      class GridsAPI < ::API::OpenProjectAPI
        resources :grids do
          helpers do
            def bogus_grid
              OpenStruct.new(
                row_count: 4,
                column_count: 5,
                widgets: [
                  OpenStruct.new(
                    identifier: 'work_packages_assigned',
                    start_row: 4,
                    end_row: 5,
                    start_column: 1,
                    end_column: 2
                  ),
                  OpenStruct.new(
                    identifier: 'work_packages_created',
                    start_row: 1,
                    end_row: 2,
                    start_column: 1,
                    end_column: 2
                  ),
                  OpenStruct.new(
                    identifier: 'work_packages_watched',
                    start_row: 2,
                    end_row: 4,
                    start_column: 4,
                    end_column: 5
                  ),
                  OpenStruct.new(
                    identifier: 'work_packages_calendar',
                    start_row: 1,
                    end_row: 2,
                    start_column: 4,
                    end_column: 6
                  )
                ]
              )
            end
          end

          post do
            # TODO: replace mock with actual creation
            params = API::V3::ParseResourceParamsService
                     .new(current_user, representer: GridRepresenter)
                     .call(request_body)
                     .result

            grid = OpenStruct.new(bogus_grid.to_h.merge(params))

            status 201
            GridRepresenter.create(grid,
                                   current_user: current_user,
                                   embed_links: true)
          end

          route_param :id do
            get do
              # TODO: replace mock with actual fetching
              GridRepresenter.new(bogus_grid, current_user: current_user)
            end

            patch do
              # TODO: replace mock with actual update
              params = API::V3::ParseResourceParamsService
                       .new(current_user, representer: GridRepresenter)
                       .call(request_body)
                       .result

              grid = OpenStruct.new(bogus_grid.to_h.merge(params))

              GridRepresenter.create(grid,
                                     current_user: current_user,
                                     embed_links: true)
            end
          end
        end
      end
    end
  end
end
