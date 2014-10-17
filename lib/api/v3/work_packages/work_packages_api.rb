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
              VALID_REQUEST_ATTRIBUTES = ['_type', 'lockVersion']
              VALID_UPDATE_ATTRIBUTES = VALID_REQUEST_ATTRIBUTES + ['subject', 'parentId']

              attr_reader :work_package

              def check_work_package_attributes
                attributes = JSON.parse(env['api.request.input'])
                invalid_attributes = invalid_work_package_update_attributes(attributes)

                fail Errors::Validation.new(nil) unless invalid_attributes.empty?
              end

              def invalid_work_package_update_attributes(attributes)
                attributes.delete_if { |key, _| VALID_UPDATE_ATTRIBUTES.include? key }
              end

              def check_parent_update
                attributes = JSON.parse(env['api.request.input'])

                authorize(:manage_subtasks, context: @work_package.project) if attributes.include? 'parentId'

                parent_id = attributes['parentId'].blank? ? nil : attributes['parentId'].to_i

                if parent_id && !WorkPackage.visible(current_user).exists?(parent_id)
                  @work_package.errors.add(:parent_id, :not_a_valid_parent)
                  fail Errors::Validation.new(@work_package)
                end
              end

              def work_package_attributes
                attributes = JSON.parse(env['api.request.input'])
                attributes.delete_if { |key, _| VALID_REQUEST_ATTRIBUTES.include? key }
              end
            end

            before do
              @work_package = WorkPackage.find(params[:id])
              model = ::API::V3::WorkPackages::WorkPackageModel.new(@work_package)
              @representer =  ::API::V3::WorkPackages::WorkPackageRepresenter.new(model, { current_user: current_user }, :activities, :users)
            end

            get do
              authorize({ controller: :work_packages_api, action: :get }, context: @work_package.project)
              @representer
            end

            patch do
              authorize(:edit_work_packages, context: @work_package.project)
              check_work_package_attributes # fails if request contains invalid attributes
              check_parent_update # fails if parent update is invalid

              @representer.from_json(work_package_attributes.to_json)
              @representer.represented.sync
              if @representer.represented.model.valid? && @representer.represented.save
                @representer
              else
                fail Errors::Validation.new(@representer.represented.model)
              end
            end

            resource :activities do

              helpers do
                def save_work_package(work_package)
                  if work_package.save
                    model = ::API::V3::Activities::ActivityModel.new(work_package.journals.last)
                    representer = ::API::V3::Activities::ActivityRepresenter.new(model, { current_user: current_user })

                    representer
                  else
                    errors = work_package.errors.full_messages.join(", ")
                    fail Errors::Validation.new(work_package, description: errors)
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
                build_representer(available_assignees,
                                  ::API::V3::Users::UserModel,
                                  ::API::V3::Users::UserCollectionRepresenter,
                                  as: :available_assignees)
              end

            end

            resource :available_responsibles do

              get do
                authorize(:add_work_packages, context: @work_package.project) \
                  || authorize(:edit_work_packages, context: @work_package.project)

                available_responsibles = @work_package.assignable_responsibles
                build_representer(available_responsibles,
                                  ::API::V3::Users::UserModel,
                                  ::API::V3::Users::UserCollectionRepresenter,
                                  as: :available_responsibles)
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
