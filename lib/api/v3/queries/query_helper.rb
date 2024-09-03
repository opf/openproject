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

require "api/v3/queries/query_representer"

module API
  module V3
    module Queries
      module QueryHelper
        ##
        # @param query [Query]
        # @param contract [Class]
        # @param form_representer [Class]
        #
        # Additionally, two parameters are accepted under the hood.
        #
        # # request_body
        # # params
        #
        # Both are applied to the query in order to adapt it.
        def create_or_update_query_form(query, contract, form_representer)
          query = update_query_from_body_and_params(query)
          contract = contract.new query, current_user
          contract.validate

          query.user = current_user

          form_result query, form_representer, ::API::Errors::ErrorBase.create_errors(contract.errors)
        end

        def form_result(query, form_representer, api_errors)
          # errors for invalid data (e.g. validation errors) are handled inside the form
          if api_errors.all? { |error| error.code == 422 }
            status 200
            form_representer.new query, current_user:, errors: api_errors
          else
            fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
          end
        end

        def update_query(query, request_body, current_user)
          rep = representer.new(query, current_user:)
          query = rep.from_hash request_body

          call = raise_invalid_query_on_service_failure do
            ::Queries::UpdateService.new(model: query, user: current_user).call query
          end

          representer.new call.result, current_user:, embed_links: true
        end

        def representer
          ::API::V3::Queries::QueryRepresenter
        end

        def update_query_from_get_params(query)
          query_params = ActionDispatch::Request.new(request.env).query_parameters

          if query_params.is_a?(Hash) && !query_params.empty?
            UpdateQueryFromV3ParamsService.new(query, current_user).call(query_params)
          end
        end

        def update_query_from_body_and_params(query)
          representer = ::API::V3::Queries::QueryRepresenter.create(query, current_user:)

          # Update the query from the hash
          representer.from_hash(Hash(request_body)).tap do |parsed_query|
            # Note that we do not deal with failures here. The query
            # needs to be validated later.
            update_query_from_get_params parsed_query
          end
        end
      end
    end
  end
end
