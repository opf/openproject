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
    module TimeEntries
      class AvailableWorkPackagesOnEditAPI < ::API::OpenProjectAPI
        after_validation do
          authorize_in_work_package(%i[log_own_time edit_own_time_entries], work_package: @time_entry.work_package) do
            authorize_in_project(%i[log_time edit_time_entries], project: @time_entry.project)
          end
        end

        helpers AvailableWorkPackagesHelper

        helpers do
          def allowed_scope
            edit_scope = WorkPackage.where(project_id: Project.allowed_to(User.current, :edit_time_entries))
            edit_own_scope = WorkPackage.where(id: WorkPackage.allowed_to(User.current, :edit_own_time_entries))
            ongoing_scope = WorkPackage.where(id: TimeEntry.visible_ongoing.select(:work_package_id))

            edit_scope
              .or(edit_own_scope)
              .or(ongoing_scope)
          end
        end

        resources :available_work_packages do
          get do
            available_work_packages_collection(allowed_scope)
          end
        end
      end
    end
  end
end
