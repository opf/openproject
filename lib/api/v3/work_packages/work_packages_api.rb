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
      class WorkPackagesAPI < Grape::API
        resources :work_packages do

          params do
            requires :id, desc: 'Work package id'
          end
          namespace ':id' do

            helpers do
              attr_reader :work_package

              def save_work_package
                send_notifications = !(params.has_key?(:notify) && params[:notify] == 'false')

                UserMailer.with_deliveries(send_notifications) do
                  @representer.represented.save
                end
              end

              def decorate_work_package(work_package)
                @representer = ::API::V3::WorkPackages::WorkPackageRepresenter.new(work_package, { current_user: current_user }, :activities, :users)
              end

              def patch_request_body
                env['api.request.input']
              end

              def patch_request_valid?
                contract = WorkPackageContract.new(@representer.represented, current_user)

                # Although the contract triggers the ActiveModel validations on
                # the work package, it does not merge the contract errors with
                # the model errors. Thus, we need to do it manually.
                unless contract.validate
                  contract.errors.keys.each do |key|
                    contract.errors[key].each do |message|
                      @representer.represented.errors.add(key, message)
                    end
                  end
                end

                @representer.represented.errors.count == 0
              end
            end

            before do
              @work_package = WorkPackage.find(params[:id])
              decorate_work_package(@work_package)
            end

            get do
              authorize({ controller: :work_packages_api, action: :get }, context: @work_package.project)
              @representer
            end

            patch do
              @representer.represented.lock_version = nil # enforces availibility validation of lock_version

              @representer.from_json(patch_request_body)

              if patch_request_valid? && save_work_package
                decorate_work_package(@work_package.reload)
                @representer
              else
                fail ::API::Errors::ErrorBase.create(@representer.represented.errors)
              end
            end

            resource :activities do

              helpers do
                def save_work_package(work_package)
                  if work_package.save
                    representer = ::API::V3::Activities::ActivityRepresenter.new(work_package.journals.last, current_user: current_user)

                    representer
                  else
                    fail ::API::Errors::Validation.new(work_package)
                  end
                end
              end

              params do
                requires :comment, type: String
              end
              post do
                authorize({ controller: :journals, action: :new }, context: @work_package.project)

                @work_package.journal_notes = params[:comment]

                save_work_package(@work_package)
              end

            end

            resource :available_assignees do

              get do
                authorize(:add_work_packages, context: @work_package.project) \
                  || authorize(:edit_work_packages, context: @work_package.project)

                available_assignees = @work_package.assignable_assignees
                ::API::V3::Users::UserCollectionRepresenter.new(available_assignees, as: :available_assignees)
              end

            end

            resource :available_responsibles do

              get do
                authorize(:add_work_packages, context: @work_package.project) \
                  || authorize(:edit_work_packages, context: @work_package.project)

                available_responsibles = @work_package.assignable_responsibles
                ::API::V3::Users::UserCollectionRepresenter.new(available_responsibles, as: :available_responsibles)
              end

            end

            mount ::API::V3::WorkPackages::WatchersAPI
            mount ::API::V3::WorkPackages::StatusesAPI
            mount ::API::V3::Relations::RelationsAPI

          end

        end
      end
    end
  end
end
