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
    module UserPreferences
      class PreferencesByUserAPI < ::API::OpenProjectAPI
        resource :preferences do
          # The empty namespaces are added so that anonymous users can receive a 401 response
          namespace "" do
            after_validation do
              authorize_by_with_raise(current_user.allowed_globally?(:manage_user) || @user == current_user)
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: UserPreference,
                                                           instance_generator: ->(*) { @user.pref })
                                                      .mount
          end

          namespace "" do
            after_validation do
              authorize_by_with_raise(current_user.allowed_globally?(:manage_user) ||
                                        (current_user.logged? && @user == current_user)) do
                if current_user.anonymous?
                  raise API::Errors::Unauthenticated
                else
                  raise API::Errors::Unauthorized
                end
              end
            end

            patch &::API::V3::Utilities::Endpoints::Update.new(model: UserPreference,
                                                               instance_generator: ->(*) { @user.pref })
                                                          .mount
          end
        end
      end
    end
  end
end
