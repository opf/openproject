#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# In understand this file sets up routing for the Storages API based on
# the Grape REST API Framework.
# ToDo: I understand the naming of this file follows the API::V::Storages::StoragesAPI module
# names, just that this starts in storages/lib/?
# Is it Grape that somehow knows how to load this file? What is the Grape load order?
module API
  module V3
    module Storages
      # OpenProjectAPI is a simple subclass of Grape::API that handles patches.
      class StoragesAPI < ::API::OpenProjectAPI
        helpers do
          def visible_storages_scope
            ::Storages::Storage.visible(current_user)
          end
        end

        # ToDo: The "resources" keyword is from config/routes.rb.
        # What does "resources" mean in the context of Grape? Just like in routes.rb?
        resources :storages do
          # Didn't understand route_param in Grape...
          route_param :storage_id, type: Integer, desc: 'Storage id' do
            # Execute the do...end lines after parameter validation but before the actual
            # call to the API method.
            # Please see: The after_validation call-back in Grape:
            # https://github.com/ruby-grape/grape#before-after-and-finally
            after_validation do
              @storage = visible_storages_scope.find(params[:storage_id])
            end

            # I understand that the line below defined a reaction to a GET request...
            # ToDo: What is this ampersand "&" before the ::API?
            # ToDo: Any documentation on API endpoints?
            get &::API::V3::Utilities::Endpoints::Show.new(model: ::Storages::Storage).mount
          end
        end
      end
    end
  end
end
