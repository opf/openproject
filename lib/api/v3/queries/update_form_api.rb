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

require 'api/v3/queries/query_representer'
require 'queries/create_query_service'

module API
  module V3
    module Queries
      class UpdateFormAPI < ::API::OpenProjectAPI
        resource :form do
          helpers ::API::V3::Queries::CreateQuery

          post do
            query = @query
            representer = ::API::V3::Queries::QueryRepresenter.create query, current_user: current_user
            query = representer.from_hash Hash(request_body)
            contract = ::Queries::UpdateContract.new query, current_user
            contract.validate

            query.user = current_user

            api_errors = ::API::Errors::ErrorBase.create_errors(contract.errors)

            # errors for invalid data (e.g. validation errors) are handled inside the form
            if api_errors.all? { |error| error.code == 422 }
              status 200
              UpdateFormRepresenter.new query, current_user: current_user, errors: api_errors
            else
              fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
            end
          end
        end
      end
    end
  end
end
