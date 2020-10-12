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

require 'api/v3/activities/activity_representer'

module API
  module V3
    module Activities
      class ActivitiesAPI < ::API::OpenProjectAPI
        resources :activities do
          route_param :id, type: Integer, desc: 'Activity ID' do
            after_validation do
              @activity = Journal.find(declared_params[:id])

              authorize_by_with_raise @activity.journable.visible?(current_user) do
                raise API::Errors::NotFound
              end
            end

            helpers do
              def aggregated_activity(activity)
                Journal::AggregatedJournal.containing_journal(activity)
              end

              def save_activity(activity)
                unless activity.save
                  fail ::API::Errors::ErrorBase.create_and_merge_errors(activity.errors)
                end
              end

              def authorize_edit_own(activity)
                authorize_by_with_raise activity.editable_by?(current_user)
              end
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: ::Journal,
                                                           api_name: 'Activity',
                                                           instance_generator: ->(*) { aggregated_activity(@activity) })
                                                      .mount

            params do
              requires :comment, type: String
            end

            patch do
              # TODO: Write a journal update notes service and mount default endpoint
              authorize_edit_own(@activity)
              @activity.notes = declared_params[:comment]
              save_activity(@activity)

              ActivityRepresenter.new(aggregated_activity(@activity), current_user: current_user)
            end
          end
        end
      end
    end
  end
end
