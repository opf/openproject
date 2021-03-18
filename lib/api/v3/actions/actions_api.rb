#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Actions
      class ActionsAPI < ::API::OpenProjectAPI
        resources :actions do
          get &API::V3::Utilities::Endpoints::SqlIndex
                 .new(model: Action)
                 .mount

          params do
            requires :id, type: String, desc: 'The action identifier'
          end
          namespace '*id' do
            helpers do
              def scope
                ::Queries::Actions::ActionQuery.new(user: current_user)
                                               .where('id', '=', params[:id])
                                               .results
              end
            end

            after_validation do
              raise ::API::Errors::NotFound.new unless scope.exists?
            end

            get do
              ::API::V3::Utilities::SqlRepresenterWalker
                .new(scope.limit(1),
                     embed: {},
                     select: { 'id' => {}, '_type' => {}, 'self' => {} },
                     current_user: current_user)
                .walk(API::V3::Actions::ActionSqlRepresenter)
            end
          end
        end
      end
    end
  end
end
