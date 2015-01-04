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
    module Activities
      class ActivitiesAPI < ::Cuba
        include API::Helpers

        def save_activity(activity)
          if activity.save
            representer = ::API::V3::Activities::ActivityRepresenter.new(activity)

            representer.to_json
          else
            fail ::API::Errors::ErrorBase.create(activity.errors.dup)
          end
        end

        def authorize_edit_own(activity)
          return authorize({ controller: :journals, action: :edit }, context: @activity.journable.project)
          raise API::Errors::Unauthorized.new(current_user) unless activity.editable_by?(current_user)
        end

        define do
          res.headers['Content-Type'] = 'application/json; charset=utf-8'

          on ':id' do |id|
            @activity = Journal.find(id)
            @representer = ::API::V3::Activities::ActivityRepresenter.new(@activity, current_user: current_user)

            on get do
              authorize(:view_project, context: @activity.journable.project)
              res.write @representer.to_json
            end

            on req.patch?, param('comment') do |comment|
              authorize_edit_own(@activity)

              @activity.notes = comment

              res.write save_activity(@activity)
            end
          end
        end
      end

      ActivitiesAPI.use(Rack::PostBodyContentTypeParser)
    end
  end
end
