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

require 'api/v3/work_packages/work_package_representer'

module API
  module V3
    module Projects
      class AvailableWorkPackagesAPI < ::API::OpenProjectAPI
        resources :work_packages do
          before do
            authorize(:view_project, context: @project) do
              raise API::Errors::NotFound.new
            end
          end

          helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers

          post do
            @work_package = WorkPackage.new(project: @project,
                                            author: current_user,
                                            created_at: Time.now)
            @work_package.type = Type.where(is_default: true).first
            @work_package.save(validate: false)
            write_work_package_attributes
            @work_package.lock_version = 1

            send_notifications = !(params.has_key?(:notify) && params[:notify] == 'false')
            update_service = UpdateWorkPackageService.new(current_user,
                                                          @work_package,
                                                          nil,
                                                          send_notifications,
                                                          WorkPackageObserver)

            if write_request_valid? && update_service.save
              @work_package.reload

              WorkPackages::WorkPackageRepresenter.create(@work_package,
                                            current_user: current_user)
            else
              errors = ::API::Errors::ErrorBase.create(@work_package.errors.dup)
              @work_package.destroy
              fail errors
            end
          end
        end

        mount ::API::V3::WorkPackages::Form::FormAPI
      end
    end
  end
end
