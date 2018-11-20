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
            include API::Utilities::ParamsHelper
          end

          get do
            query = ParamsToQueryService
                    .new(Grid, current_user)
                    .call(params)

            if query.valid?
              GridCollectionRepresenter.new(query.results,
                                            api_v3_paths.time_entries,
                                            page: to_i_or_nil(params[:offset]),
                                            per_page: resolve_page_size(params[:pageSize]),
                                            current_user: current_user)
            else
              raise ::API::Errors::InvalidQuery.new(query.errors.full_messages)
            end
          end

          post do
            params = API::V3::ParseResourceParamsService
                     .new(current_user, representer: GridRepresenter)
                     .call(request_body)
                     .result

            call = ::Grids::CreateService
                   .new(user: current_user)
                   .call(attributes: params)

            if call.success?
              GridRepresenter.create(call.result,
                                     current_user: current_user,
                                     embed_links: true)
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end
          end

          mount CreateFormAPI

          route_param :id do
            get do
              # TODO: replace mock with actual fetching
              GridRepresenter.new(MyPageGrid.new_default(current_user),
                                  current_user: current_user)
            end

            patch do
              # TODO: replace mock with actual update
              params = API::V3::ParseResourceParamsService
                       .new(current_user, representer: GridRepresenter)
                       .call(request_body)
                       .result

              # TODO: determine grid class based on the page parameter
              call = ::Grids::SetAttributesService
                     .new(user: current_user,
                          grid: MyPageGrid.new_default(current_user),
                          contract_class: ::Grids::UpdateContract)
                     .call(params)

              GridRepresenter.create(call.result,
                                     current_user: current_user,
                                     embed_links: true)
            end
          end
        end
      end
    end
  end
end
