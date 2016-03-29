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
require 'create_work_package_service'

module API
  module V3
    module WorkPackages
      module CreateWorkPackages
        include ::API::V3::WorkPackages::WorkPackagesSharedHelpers

        def create_work_packages(request_body, current_user)
          attributes = get_create_attributes(request_body)

          yield(attributes) if block_given?

          result = create_work_package(current_user,
                                       attributes,
                                       notify_according_to_params)

          represent_create_result(result, current_user)
        end

        private

        def represent_create_result(result, current_user)
          if result.success?
            work_package = result.result
            WorkPackages::WorkPackageRepresenter.create(work_package.reload,
                                                        current_user: current_user,
                                                        embed_links: true)
          else
            fail ::API::Errors::ErrorBase.create_and_merge_errors(result.errors)
          end
        end

        def get_create_attributes(request_body)
          write_work_package_attributes(WorkPackage.new, request_body || {})
            .changes.each_with_object({}) { |(k, v), h| h[k] = v.last }
        end

        def create_work_package(current_user, attributes, send_notification)
          create_service = CreateWorkPackageService.new(user: current_user)

          create_service.call(attributes: attributes,
                              send_notifications: send_notification)
        end
      end
    end
  end
end
