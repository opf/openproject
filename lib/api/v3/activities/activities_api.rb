#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
    module Activities
      class ActivitiesAPI < Grape::API

        resources :activities do

          params do
            requires :id, desc: 'Activity id'
          end
          namespace ':id' do

            before do
              @activity = Journal.find(params[:id])
              model = ::API::V3::Activities::ActivityModel.new(@activity)
              @representer =  ::API::V3::Activities::ActivityRepresenter.new(model)
            end

            get do
              authorize(:view_project, context: @activity.journable.project)
              @representer.to_json
            end

            helpers do
              def save_activity(activity)
                if activity.save
                  model = ::API::V3::Activities::ActivityModel.new(activity)
                  representer = ::API::V3::Activities::ActivityRepresenter.new(model)

                  representer.to_json
                else
                  errors = activity.errors.full_messages.join(", ")
                  fail Errors::Validation.new(activity, description: errors)
                end
              end
            end

            params do
              requires :comment, type: String
            end
            put do
              authorize({ controller: :journals, action: :edit }, context: @activity.journable.project)

              @activity.notes = params[:comment]

              save_activity(@activity)
            end

          end

        end

      end
    end
  end
end
