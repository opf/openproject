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

require 'api/v3/activities/activity_representer'
require 'api/v3/work_packages/work_package_contract'
require 'api/v3/work_packages/work_package_representer'
require 'api/v3/work_packages/form/work_package_payload_representer'

module API
  module V3
    module WorkPackages
      class WorkPackagesAPI < ::API::OpenProjectAPI
        resources :work_packages do
          params do
            requires :id, desc: 'Work package id'
          end
          route_param :id do
            helpers do
              attr_reader :work_package

              def work_package_representer
                WorkPackageRepresenter.create(@work_package,
                                              current_user: current_user)
              end

              def write_work_package_attributes
                if request_body
                  begin
                    # we need to merge the JSON two times:
                    # In Pass 1 the representer only has custom fields for the current WP type
                    # After Pass 1 the correct type information is merged into the WP
                    # In Pass 2 the representer is created with the new type info and will be able
                    # to also parse custom fields successfully
                    merge_json_into_work_package!(request_body.to_json)
                    merge_json_into_work_package!(request_body.to_json)
                  rescue ::API::Errors::Form::InvalidResourceLink => e
                    fail ::API::Errors::Validation.new(e.message)
                  end
                end
              end

              # merges the given JSON representation into @work_package
              def merge_json_into_work_package!(json)
                payload = Form::WorkPackagePayloadRepresenter.create(
                  @work_package,
                  enforce_lock_version_validation: true)
                payload.from_json(json)
              end

              def request_body
                env['api.request.body']
              end

              def write_request_valid?
                contract = WorkPackageContract.new(@work_package, current_user)

                contract_valid = contract.validate
                represented_valid = @work_package.valid?

                return true if contract_valid && represented_valid

                # We need to merge the contract errors with the model errors in
                # order to have them available at one place.
                contract.errors.keys.each do |key|
                  contract.errors[key].each do |message|
                    @work_package.errors.add(key, message)
                  end
                end

                false
              end
            end

            before do
              @work_package = WorkPackage.find(params[:id])

              authorize(:view_work_packages, context: @work_package.project) do
                raise API::Errors::NotFound.new
              end
            end

            get do
              work_package_representer
            end

            patch do
              write_work_package_attributes

              send_notifications = !(params.has_key?(:notify) && params[:notify] == 'false')
              update_service = UpdateWorkPackageService.new(current_user,
                                                            @work_package,
                                                            nil,
                                                            send_notifications)

              if write_request_valid? && update_service.save
                @work_package.reload

                work_package_representer
              else
                fail ::API::Errors::ErrorBase.create(@work_package.errors.dup)
              end
            end

            resource :activities do
              helpers do
                def save_work_package(work_package)
                  if work_package.save
                    Activities::ActivityRepresenter.new(work_package.journals.last,
                                                        current_user: current_user)
                  else
                    fail ::API::Errors::Validation.new(work_package)
                  end
                end
              end

              params do
                requires :comment, type: String
              end
              post do
                authorize({ controller: :journals, action: :new },
                          context: @work_package.project) do
                  raise ::API::Errors::NotFound.new
                end

                @work_package.journal_notes = params[:comment]

                save_work_package(@work_package)
              end
            end

            mount ::API::V3::WorkPackages::WatchersAPI
            mount ::API::V3::Relations::RelationsAPI
            mount ::API::V3::WorkPackages::Form::FormAPI
          end

          mount ::API::V3::WorkPackages::Schema::WorkPackageSchemasAPI
        end
      end
    end
  end
end
