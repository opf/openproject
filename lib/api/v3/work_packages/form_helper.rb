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

require 'api/v3/work_packages/work_package_payload_representer'

module API
  module V3
    module WorkPackages
      module FormHelper
        extend Grape::API::Helpers

        def respond_with_work_package_form(work_package, contract_class:, form_class:, action: :update)
          parameters = parse_body

          result = ::WorkPackages::SetAttributesService
                   .new(user: current_user, work_package: work_package, contract_class: contract_class)
                   .call(parameters)

          api_errors = ::API::Errors::ErrorBase.create_errors(result.errors)

          # errors for invalid data (e.g. validation errors) are handled inside the form
          if only_validation_errors(api_errors)
            status 200
            form_class.new(work_package,
                           current_user: current_user,
                           errors: api_errors,
                           action: action)
          else
            fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
          end
        end

        private

        def only_validation_errors(errors)
          errors.all? { |error| error.code == 422 }
        end

        def parse_body
          ::API::V3::WorkPackages::ParseParamsService
            .new(current_user)
            .call(request_body)
        end
      end
    end
  end
end
