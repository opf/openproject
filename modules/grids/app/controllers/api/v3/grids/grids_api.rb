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
    module Grids
      class GridsAPI < ::API::OpenProjectAPI
        resources :grids do
          helpers do
            include API::Utilities::UrlPropsParsingHelper
          end

          get do
            query = ParamsToQueryService
                    .new(::Grids::Grid, current_user, query_class: ::Grids::Query)
                    .call(params)

            if query.valid?
              GridCollectionRepresenter.new(query.results,
                                            self_link: api_v3_paths.grids,
                                            grid_scope: query.filter_scope,
                                            page: to_i_or_nil(params[:offset]),
                                            per_page: resolve_page_size(params[:pageSize]),
                                            current_user:)
            else
              raise_query_errors query
            end
          end

          post &::API::V3::Utilities::Endpoints::Create.new(model: ::Grids::Grid).mount

          mount ::API::V3::Grids::CreateFormAPI
          mount ::API::V3::Grids::Schemas::GridSchemaAPI

          route_param :id, type: Integer, desc: "Grid ID" do
            after_validation do
              @grid = ::Grids::Query
                      .new(user: current_user)
                      .results
                      .find(params["id"])
            end

            get do
              GridRepresenter.new(@grid,
                                  current_user:)
            end

            mount ::API::V3::Attachments::AttachmentsByGridAPI

            # Hack to be able to use the Default* mount while having the permission check
            # not affecting the GET request
            namespace do
              after_validation do
                unless ::Grids::UpdateContract.new(@grid, current_user).edit_allowed?
                  raise ActiveRecord::RecordNotFound
                end
              end

              patch &::API::V3::Utilities::Endpoints::Update.new(model: ::Grids::Grid,
                                                                 params_modifier: ->(params) do
                                                                   params[:widgets]&.each do |widget|
                                                                     # Need to parse the widget options again
                                                                     # as the right representer needs to be used
                                                                     # which is specific to the @grid.class. The parsing
                                                                     # before strives to be agnostic.
                                                                     strategy = ::Grids::Configuration
                                                                                .widget_strategy(@grid.class,
                                                                                                 widget.identifier)
                                                                     representer = strategy.options_representer.constantize

                                                                     widget.options = representer
                                                                                      .new(OpenStruct.new, current_user:)
                                                                                      .from_hash(widget.options)
                                                                                      .to_h
                                                                                      .with_indifferent_access
                                                                   end

                                                                   params
                                                                 end)
                                                            .mount
              delete &::API::V3::Utilities::Endpoints::Delete.new(model: ::Grids::Grid).mount

              mount ::API::V3::Grids::UpdateFormAPI
            end
          end
        end
      end
    end
  end
end
