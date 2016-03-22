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

require 'work_packages/base_contract'
require 'api/v3/work_packages/work_package_payload_representer'

module API
  module V3
    module WorkPackages
      module WorkPackagesSharedHelpers
        extend Grape::API::Helpers

        def merge_hash_into_work_package!(hash, work_package)
          payload = ::API::V3::WorkPackages::WorkPackagePayloadRepresenter.create(work_package)
          payload.from_hash(hash)
        end

        def write_work_package_attributes(work_package, request_body, reset_lock_version: false)
          if request_body
            work_package.lock_version = nil if reset_lock_version
            # we need to merge the JSON two times:
            # In Pass 1 the representer only has custom fields for the current WP type/project
            # After Pass 1 the correct type/project information is merged into the WP
            # In Pass 2 the representer is created with the new type/project info and will be able
            # to also parse custom fields successfully
            merge_hash_into_work_package!(request_body, work_package)

            if custom_field_context_changed?(work_package)
              merge_hash_into_work_package!(request_body, work_package)
            end
          end
        end

        def create_work_package_form(work_package, contract_class:, form_class:)
          write_work_package_attributes(work_package, request_body, reset_lock_version: true)
          contract = contract_class.new(work_package, current_user)
          contract.validate

          api_errors = ::API::Errors::ErrorBase.create_errors(contract.errors)

          # errors for invalid data (e.g. validation errors) are handled inside the form
          if only_validation_errors(api_errors)
            status 200
            form_class.new(work_package, current_user: current_user, errors: api_errors)
          else
            fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
          end
        end

        private

        def custom_field_context_changed?(work_package)
          work_package.type_id_changed? ||
            work_package.project_id_changed?
        end

        def only_validation_errors(errors)
          errors.all? { |error| error.code == 422 }
        end
      end
    end
  end
end
