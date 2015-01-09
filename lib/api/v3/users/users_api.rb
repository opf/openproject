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
    module Users
      class UsersAPI < Grape::API
        resources :users do

          params do
            requires :id, desc: 'User\'s id'
          end
          namespace ':id' do

            before do
              @user  = User.find(params[:id])
            end

            get do
              UserRepresenter.new(@user)
            end

            delete do
              if DeleteUserService.new(@user, User.current).call
                status 202
              else
                fail ::API::Errors::Unauthorized
              end
            end

            namespace :lock do

              # Authenticate lock transitions
              before do
                if !User.current.admin?
                  fail ::API::Errors::Unauthorized
                end
              end

              desc 'Set lock on user account'
              post do
                # Silently ignore lock -> lock transition
                if @user.active? || @user.locked?
                  @user.lock! unless @user.locked?

                  status 200
                  UserRepresenter.new(@user)
                else
                  fail ::API::Errors::InvalidUserStatusTransition
                end
              end

              desc 'Remove lock on user account'
              delete do
                # Silently ignore active -> active transition
                if @user.locked? || @user.active?
                  @user.activate! unless @user.active?

                  status 200
                  UserRepresenter.new(@user)
                else
                  fail ::API::Errors::InvalidUserStatusTransition
                end
              end
            end
          end

        end
      end
    end
  end
end
