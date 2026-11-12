# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module Favorites
      class FavoriteActionsAPI < ::API::OpenProjectAPI
        namespace :favorite do
          after_validation do
            getter = configuration.fetch(:favorite_object_getter)
            @favorite_object = instance_eval(&getter)

            unless @favorite_object&.visible?(current_user)
              raise API::Errors::NotFound
            end

            unless current_user.logged?
              raise API::Errors::Unauthorized
            end
          end

          desc "Mark as favorite"
          post do
            @favorite_object.set_favorited(current_user, favorited: true)
            status 204
          end

          desc "Unmark as favorite"
          delete do
            @favorite_object.set_favorited(current_user, favorited: false)
            status 204
          end
        end
      end
    end
  end
end
