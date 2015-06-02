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

require 'securerandom'
require 'api/v3/queries/query_representer'

module API
  module V3
    module Queries
      class QueriesAPI < ::API::OpenProjectAPI
        resources :queries do
          params do
            requires :id, desc: 'Query id'
          end
          route_param :id do
            before do
              @query = Query.find(params[:id])
              @representer = QueryRepresenter.new(@query)
            end

            helpers do
              def authorize_by_policy(action)
                authorize_by_with_raise do
                  QueryPolicy.new(current_user).allowed?(@query, action)
                end
              end
            end

            patch :star do
              authorize_by_policy(:star)

              # Query name is not user-visible, but apparently used as CSS class. WTF.
              # Normalizing the query name can result in conflicts and empty names in case all
              # characters are filtered out. A random name doesn't have these problems.
              query_menu_item = MenuItems::QueryMenuItem.find_or_initialize_by_navigatable_id(
                @query.id, name: SecureRandom.uuid, title: @query.name
              )
              query_menu_item.save!
              @representer
            end

            patch :unstar do
              authorize_by_policy(:unstar)

              query_menu_item = @query.query_menu_item
              return @representer if @query.query_menu_item.nil?
              query_menu_item.destroy
              @query.reload
              @representer
            end
          end
        end
      end
    end
  end
end
