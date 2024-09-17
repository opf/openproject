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
    module Users
      class UsersAPI < ::API::OpenProjectAPI
        helpers do
          def user_transition(allowed)
            if allowed
              yield

              # Show updated user
              status 200
              UserRepresenter.create(@user, current_user:)
            else
              fail ::API::Errors::InvalidUserStatusTransition
            end
          end
        end

        resources :users do
          # The namespace only exists to add the after_validation callback
          namespace "" do
            after_validation do
              authorize_globally(:create_user)
            end

            post &::API::V3::Utilities::Endpoints::Create.new(model: User).mount
          end

          # The namespace only exists to add the after_validation callback
          namespace "" do
            after_validation do
              authorize_globally(:manage_user)
            end

            get &::API::V3::Utilities::Endpoints::SqlFallbackedIndex
                   .new(model: User,
                        scope: -> { User.user.includes(:preference) })
                   .mount
          end

          mount ::API::V3::Users::Schemas::UserSchemaAPI
          mount ::API::V3::Users::CreateFormAPI

          params do
            requires :id, desc: "User's id"
          end
          route_param :id do
            after_validation do
              @user =
                if params[:id] == "me"
                  User.current
                else
                  User.find_by_unique!(params[:id])
                end
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: User).mount
            patch &::API::V3::Utilities::Endpoints::Update.new(model: User).mount
            delete &::API::V3::Utilities::Endpoints::Delete.new(model: User, success_status: 202).mount

            mount ::API::V3::Users::UpdateFormAPI
            mount ::API::V3::UserPreferences::PreferencesByUserAPI

            namespace :lock do
              # Authenticate lock transitions
              after_validation do
                authorize_admin
              end

              desc "Set lock on user account"
              post do
                user_transition(@user.active? || @user.locked?) do
                  @user.lock! unless @user.locked?
                end
              end

              desc "Remove lock on user account"
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
