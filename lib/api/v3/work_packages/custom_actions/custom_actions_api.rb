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

module API
  module V3
    module WorkPackages
      module CustomActions
        class CustomActionsAPI < ::API::OpenProjectAPI
          resources :custom_actions do
            params do
              requires :action_id, desc: 'Custom action id', type: Integer
            end
            route_param :action_id do
              post do
                attributes = case params[:action_id]
                             when 1
                               { assigned_to: nil }
                             when 2
                               { status: @work_package.new_statuses_allowed_to(current_user).detect(&:is_closed) || Status.default }
                             when 3
                               { priority: IssuePriority.reorder(position: :desc).limit(1).first }
                             else
                               { status: @work_package.new_statuses_allowed_to(current_user).detect { |s| !s.is_closed } || Status.default,
                                 priority: IssuePriority.default,
                                 assigned_to: @work_package.project.users.first }
                             end

                call = ::WorkPackages::UpdateService
                       .new(
                         user: current_user,
                         work_package: @work_package
                       )
                       .call(attributes: attributes,
                             send_notifications: notify_according_to_params)

                if call.success?
                  @work_package.reload

                  status 200
                  work_package_representer
                else
                  fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
                end
              end
            end
          end
        end
      end
    end
  end
end
