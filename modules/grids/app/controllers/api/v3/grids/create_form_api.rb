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

module API
  module V3
    module Grids
      class CreateFormAPI < ::API::OpenProjectAPI
        resource :form do
          helpers do
            include API::V3::Utilities::FormHelper
          end

          post do
            params = API::V3::ParseResourceParamsService
                     .new(current_user, representer: GridPayloadRepresenter)
                     .call(request_body)
                     .result

            grid_class = ::Grids::Configuration.grid_for_page(params.delete(:page))
            grid = grid_class.new_default(current_user)

            call = ::Grids::SetAttributesService
                   .new(user: current_user,
                        grid: grid,
                        contract_class: ::Grids::CreateContract)
                   .call(params)

            api_errors = ::API::Errors::ErrorBase.create_errors(call.errors)

            # errors for invalid data (e.g. validation errors) are handled inside the form
            if only_validation_errors(api_errors)
              status 200
              CreateFormRepresenter.new(call.result,
                                        errors: api_errors,
                                        current_user: current_user)
            else
              fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
            end
          end
        end
      end
    end
  end
end
