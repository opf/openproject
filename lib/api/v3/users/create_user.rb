#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'api/v3/users/user_representer'
require 'users/create_user_service'

module API
  module V3
    module Users
      module CreateUser
        extend Grape::API::Helpers
        ##
        # Call the user create service for the current request
        # and return the service result API representation
        def create_user(request_body, current_user)
          payload = ::API::V3::Users::UserRepresenter.create(User.new, current_user: current_user)
          new_user = payload.from_hash(request_body)

          result = call_service(new_user, current_user)
          represent_service_result(result, current_user)
        end

        private

        def represent_service_result(result, current_user)
          if result.success?
            status 201
            ::API::V3::Users::UserRepresenter.create(result.result, current_user: current_user)
          else
            fail ::API::Errors::ErrorBase.create_and_merge_errors(result.errors)
          end
        end

        def call_service(new_user, current_user)
          create_service = ::Users::CreateUserService.new(current_user: current_user)
          create_service.call(new_user)
        end
      end
    end
  end
end
