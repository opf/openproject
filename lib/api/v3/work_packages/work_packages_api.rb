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

module API
  module V3
    module WorkPackages
      module Helpers
        def write_work_package_attributes
          request_body = req.body.read
          if !request_body.empty?
            payload = ::API::V3::WorkPackages::Form::WorkPackagePayloadRepresenter
                      .new(@work_package, enforce_lock_version_validation: true)

            begin
              payload.from_json(request_body)
            rescue ::API::Errors::Form::InvalidResourceLink => e
              fail ::API::Errors::Validation.new(e.message)
            rescue ::MultiJson::ParseError => e
              fail ::API::Errors::ParseError.new(e.message)
            end
          end
        end

        def write_request_valid?
          contract = WorkPackageContract.new(@representer.represented, current_user)

          # We need to merge the contract errors with the model errors in
          # order to have them available at one place.
          unless contract.validate & @representer.represented.valid?
            contract.errors.keys.each do |key|
              contract.errors[key].each do |message|
                @representer.represented.errors.add(key, message)
              end
            end
          end

          @representer.represented.errors.count == 0
        end

        def save_work_package(work_package)
          if work_package.save
            representer = ::API::V3::Activities::ActivityRepresenter.new(work_package.journals.last, current_user: current_user)

            res.status = 201
            res.write representer.to_json
          else
            fail ::API::Errors::Validation.new(work_package)
          end
        end
      end

      class WorkPackagesAPI < ::Cuba
        include API::Helpers
        include API::V3::Utilities::PathHelper
        include API::V3::WorkPackages::Helpers

        attr_reader :work_package

        define do
          res.headers['Content-Type'] = 'application/json; charset=utf-8'

          on ':id' do |id|
            @work_package = WorkPackage.find(id)
            @representer = ::API::V3::WorkPackages::WorkPackageRepresenter
                           .new(@work_package, { current_user: current_user }, :activities, :users)

            env['work_package'] = @work_package
            env['work_package_representer'] = @representer

            on get, 'available_watchers' do
              authorize(:add_work_package_watchers, context: @work_package.project)

              available_watchers = @work_package.possible_watcher_users
              total = available_watchers.count
              self_link = api_v3_paths.available_watchers(@work_package.id)

              res.write ::API::V3::Users::UserCollectionRepresenter.new(available_watchers,
                                                                        total, self_link).to_json
            end

            on 'activities' do
              on post do
                authorize({ controller: :journals, action: :new }, context: @work_package.project)

                # FIXME: do we want to use Rack::PostBodyContentTypeParser here?
                request_body = req.body.read
                request_data = JSON.parse(request_body)

                if (comment = request_data['comment'])
                  @work_package.journal_notes = comment

                  save_work_package(@work_package)
                else
                  res.status = 422
                end
              end
            end

            on 'watchers' do
              run ::API::V3::WorkPackages::WatchersAPI
            end

            on 'relations' do
              run ::API::V3::Relations::RelationsAPI
            end

            on 'form' do
              run ::API::V3::WorkPackages::Form::FormAPI
            end

            on get do
              authorize({ controller: :work_packages_api, action: :get }, context: @work_package.project)
              res.write @representer.to_json
            end

            on req.patch? do
              write_work_package_attributes
              send_notifications = !(req.params.has_key?('notify') && req.params['notify'] == 'false')
              update_service = UpdateWorkPackageService.new(current_user,
                                                            @representer.represented,
                                                            nil,
                                                            send_notifications)

              if write_request_valid? && update_service.save
                @representer.represented.reload
                res.write @representer.to_json
              else
                fail ::API::Errors::ErrorBase.create(@representer.represented.errors.dup)
              end
            end
          end
        end
      end
    end
  end
end
