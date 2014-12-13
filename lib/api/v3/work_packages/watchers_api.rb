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
    module WorkPackages
      class WatchersAPI < ::Cuba
        include API::Helpers
        include API::V3::Utilities::PathHelper

        define do
          @work_package = env['work_package']

          on post, param('user_id') do |user_id|
            if current_user.id == user_id.to_i
              authorize(:view_work_packages, context: @work_package.project)
            else
              authorize(:add_work_package_watchers, context: @work_package.project)
            end

            user = User.find user_id

            Services::CreateWatcher.new(@work_package, user).run(
              -> (result) {
                res.status = if result[:created]
                               201
                             else
                               200
                end
              },
              -> (watcher) { raise ::API::Errors::Validation.new(watcher) }
            )

            res.write ::API::V3::Users::UserRepresenter.new(user).to_json
          end

          on ':user_id' do |user_id|
            on delete do
              if current_user.id == user_id.to_i
                authorize(:view_work_packages, context: @work_package.project)
              else
                authorize(:delete_work_package_watchers, context: @work_package.project)
              end

              user = User.find_by_id user_id

              Services::RemoveWatcher.new(@work_package, user).run

              res.status = 204
            end
          end

        end
      end

      WatchersAPI.use(Rack::PostBodyContentTypeParser)
    end
  end
end
