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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module UserWorkingHours
      class WorkingHoursByUserAPI < ::API::OpenProjectAPI
        resource :working_hours do
          after_validation do
            raise API::Errors::NotFound unless @user == current_user || current_user.allowed_globally?(:manage_working_times)
          end

          get do
            records = ::UserWorkingHours.visible(current_user).for_user(@user).order(valid_from: :desc)

            UserWorkingHoursCollectionRepresenter.new(
              records,
              self_link: api_v3_paths.user_working_hours(@user.id),
              current_user:
            )
          end

          post &::API::V3::Utilities::Endpoints::Create.new(
            model: ::UserWorkingHours,
            params_modifier: ->(params) { params.merge(user: @user) }
          ).mount

          route_param :working_hours_id, type: Integer, desc: "UserWorkingHours ID" do
            after_validation do
              @user_working_hours = ::UserWorkingHours
                                      .visible(current_user)
                                      .for_user(@user)
                                      .find(declared_params[:working_hours_id])
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: ::UserWorkingHours).mount

            patch &::API::V3::Utilities::Endpoints::Update.new(model: ::UserWorkingHours).mount

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: ::UserWorkingHours).mount
          end
        end
      end
    end
  end
end
