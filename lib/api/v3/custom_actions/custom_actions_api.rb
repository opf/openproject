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
    module CustomActions
      class CustomActionsAPI < ::API::OpenProjectAPI
        resources :custom_actions do
          route_param :id, type: Integer, desc: "Custom action ID" do
            helpers do
              def custom_action
                @custom_action ||= CustomAction.find(params[:id])
              end
            end

            helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers

            after_validation do
              authorize_in_any_work_package(:edit_work_packages)
            end

            get do
              ::API::V3::CustomActions::CustomActionRepresenter.new(custom_action,
                                                                    current_user:)
            end

            namespace "execute" do
              helpers do
                def parsed_params
                  @parsed_params ||= begin
                    struct = OpenStruct.new

                    representer = ::API::V3::CustomActions::CustomActionExecuteRepresenter.new(struct,
                                                                                               current_user:)
                    representer.from_hash(Hash(request_body))
                  end
                end
              end

              after_validation do
                contract = ::CustomActions::ExecuteContract.new(parsed_params, current_user)

                unless contract.valid?
                  fail ::API::Errors::ErrorBase.create_and_merge_errors(contract.errors)
                end
              end

              post do
                work_package = WorkPackage.visible.find_by(id: parsed_params.work_package_id)
                work_package.lock_version = parsed_params.lock_version

                ::CustomActions::UpdateWorkPackageService
                  .new(user: current_user,
                       action: custom_action)
                  .call(work_package:) do |call|
                  call.on_success do
                    work_package.reload

                    status 200
                    body(::API::V3::WorkPackages::WorkPackageRepresenter.create(
                           work_package,
                           current_user:,
                           embed_links: true
                         ))
                  end

                  call.on_failure do
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
end
