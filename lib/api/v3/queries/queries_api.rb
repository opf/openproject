#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
    module Queries
      class QueriesAPI < Grape::API

        resources :queries do

          params do
            requires :id, desc: 'Query id'
          end
          namespace ':id' do

            before do
              @query = Query.find(params[:id])
              model = ::API::V3::Queries::QueryModel.new(query: @query)
              @representer =  ::API::V3::Queries::QueryRepresenter.new(model)
            end

            helpers do
              def allowed_to_manage_stars?
                (@query.is_public? && current_user.allowed_to?(:manage_public_queries, @query.project)) ||
                  (!@query.is_public?  && (current_user.admin? ||
                    (current_user.allowed_to?(:save_queries, @query.project) && @query.user_id == current_user.id)))
              end
            end

            patch :star do
              authorize({ controller: :queries, action: :star }, context: @query.project, allow: allowed_to_manage_stars?)
              normalized_query_name = @query.name.parameterize.underscore
              query_menu_item = MenuItems::QueryMenuItem.find_or_initialize_by_name_and_navigatable_id(
                normalized_query_name, @query.id, title: @query.name
              )
              query_menu_item.save!
              @representer.to_json
            end

            patch :unstar do
              authorize({ controller: :queries, action: :unstar }, context: @query.project, allow: allowed_to_manage_stars?)
              query_menu_item = @query.query_menu_item
              return @representer.to_json if @query.query_menu_item.nil?
              query_menu_item.destroy
              @query.reload
              @representer.to_json
            end
          end

        end

      end
    end
  end
end
