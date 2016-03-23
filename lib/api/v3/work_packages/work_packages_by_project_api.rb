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
require 'api/v3/work_packages/work_packages_shared_helpers'
require 'work_packages/create_contract'

module API
  module V3
    module WorkPackages
      class WorkPackagesByProjectAPI < ::API::OpenProjectAPI
        resources :work_packages do
          helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers
          helpers ::API::V3::WorkPackages::WorkPackageListHelpers

          helpers do
            def create_service
              @create_service ||=
                CreateWorkPackageService.new(
                  user: current_user,
                  project: @project,
                  send_notifications: !(params.has_key?(:notify) && params[:notify] == 'false'))
            end
          end

          get do
            authorize(:view_work_packages, context: @project)
            work_packages_by_params(project: @project)
          end

          post do
            work_package = create_service.create

            write_work_package_attributes work_package, request_body

            contract = ::WorkPackages::CreateContract.new(work_package, current_user)
            if contract.validate && create_service.save(work_package)
              work_package.reload
              WorkPackages::WorkPackageRepresenter.create(work_package,
                                                          current_user: current_user,
                                                          embed_links: true)
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(contract.errors)
            end
          end

          mount ::API::V3::Projects::WorkPackageColumnsAPI
          mount ::API::V3::WorkPackages::CreateFormAPI
        end
      end
    end
  end
end
