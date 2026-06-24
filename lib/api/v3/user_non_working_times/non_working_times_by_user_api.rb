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
    module UserNonWorkingTimes
      class NonWorkingTimesByUserAPI < ::API::OpenProjectAPI
        resource :non_working_times do
          after_validation do
            raise API::Errors::NotFound unless @user == current_user || current_user.allowed_globally?(:manage_working_times)
          end

          params do
            optional :year, type: Integer, desc: "Filter by year. Defaults to the current year."
          end
          get do
            year = params[:year] || Date.current.year
            records = ::UserNonWorkingTime
                        .visible(current_user)
                        .for_user(@user)
                        .for_year(year)
                        .order(:start_date)

            UserNonWorkingTimeCollectionRepresenter.new(
              records,
              self_link: api_v3_paths.user_non_working_times(@user.id),
              current_user:
            )
          end

          post &::API::V3::Utilities::Endpoints::Create.new(
            model: ::UserNonWorkingTime,
            params_modifier: ->(params) { params.merge(user: @user) }
          ).mount

          route_param :non_working_time_id, type: Integer, desc: "UserNonWorkingTime id" do
            after_validation do
              @user_non_working_time = ::UserNonWorkingTime
                                         .visible(current_user)
                                         .for_user(@user)
                                         .find(declared_params[:non_working_time_id])
            end

            patch &::API::V3::Utilities::Endpoints::Update.new(model: ::UserNonWorkingTime).mount

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: ::UserNonWorkingTime).mount
          end
        end
      end
    end
  end
end
