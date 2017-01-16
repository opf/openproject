#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/users/user_representer'
require 'api/v3/users/paginated_user_collection_representer'

module API
  module V3
    module Users
      class UsersAPI < ::API::OpenProjectAPI
        helpers do
          def user_transition(allowed)
            if allowed
              yield

              # Show updated user
              status 200
              UserRepresenter.new(@user, current_user: current_user)
            else
              fail ::API::Errors::InvalidUserStatusTransition
            end
          end

          def allow_only_admin
            unless current_user.admin?
              fail ::API::Errors::Unauthorized
            end
          end

          def to_i_or_nil(string)
            string ? string.to_i : nil
          end
        end

        resources :users do
          helpers ::API::V3::Users::CreateUser

          post do
            allow_only_admin
            create_user(request_body, current_user)
          end

          get do
            allow_only_admin

            query = ::API::V3::ParamsToQueryService.new(User, current_user).call(params)

            if query.valid?
              users = query.results.includes(:preference)
              PaginatedUserCollectionRepresenter.new(users,
                                                     api_v3_paths.users,
                                                     page: to_i_or_nil(params[:offset]),
                                                     per_page: to_i_or_nil(params[:pageSize]),
                                                     current_user: current_user)
            else
              raise ::API::Errors::InvalidQuery.new(query.errors.full_messages)
            end
          end

          params do
            requires :id, desc: 'User\'s id'
          end
          route_param :id do
            helpers ::API::V3::Users::UpdateUser

            before do
              @user = User.find_by_unique!(params[:id])
            end

            get do
              UserRepresenter.new(@user, current_user: current_user)
            end

            patch do
              allow_only_admin
              update_user(request_body, current_user)
            end

            delete do
              if DeleteUserService.new(@user, current_user).call
                status 202
              else
                fail ::API::Errors::Unauthorized
              end
            end

            namespace :lock do
              # Authenticate lock transitions
              before do
                allow_only_admin
              end

              desc 'Set lock on user account'
              post do
                user_transition(@user.active? || @user.locked?) do
                  @user.lock! unless @user.locked?
                end
              end

              desc 'Remove lock on user account'
              delete do
                user_transition(@user.locked? || @user.active?) do
                  @user.activate! unless @user.active?
                end
              end
            end
          end
        end
      end
    end
  end
end
