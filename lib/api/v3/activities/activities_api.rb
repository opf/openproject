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

require 'api/v3/activities/activity_representer'

module API
  module V3
    module Activities
      class ActivitiesAPI < ::API::OpenProjectAPI
        resources :activities do
          params do
            requires :id, type: Integer, desc: 'Activity id'
          end
          route_param :id do
            before do
              @activity = Journal::AggregatedJournal.with_notes_id(params[:id])
              raise API::Errors::NotFound unless @activity

              authorize(:view_project, context: @activity.journable.project)
            end

            helpers do
              def save_activity(activity)
                unless activity.save
                  fail ::API::Errors::ErrorBase.create_and_merge_errors(activity.errors)
                end
              end

              def authorize_edit_own(activity)
                authorize({ controller: :journals, action: :edit },
                          context: activity.journable.project)
              end
            end

            get do
              ActivityRepresenter.new(@activity, current_user: current_user)
            end

            params do
              requires :comment, type: String
            end

            patch do
              editable_activity = Journal.find(@activity.notes_id)
              authorize_edit_own(editable_activity)
              editable_activity.notes = params[:comment]
              save_activity(editable_activity)

              ActivityRepresenter.new(@activity.reloaded, current_user: current_user)
            end
          end
        end
      end
    end
  end
end
