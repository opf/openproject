#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require 'api/v3/work_packages/create_work_packages'

module API
  module V3
    module WorkPackages
      class WorkPackagesByProjectAPI < ::API::OpenProjectAPI
        resources :work_packages do
          helpers ::API::V3::WorkPackages::CreateWorkPackages

          get do
            authorize(:view_work_packages, context: @project)

            service = raise_invalid_query_on_service_failure do
              WorkPackageCollectionFromQueryParamsService
                .new(current_user)
                .call(params.merge(project: @project))
            end

            service.result
          end

          post do
            create_work_packages(request_body, current_user) do |work_package|
              work_package.project_id = @project.id
            end
          end

          mount ::API::V3::WorkPackages::CreateProjectFormAPI
        end
      end
    end
  end
end
