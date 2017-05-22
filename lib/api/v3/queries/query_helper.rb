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
require 'queries/update_query_service'

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
          query = update_query_from_body_and_params(query, request_body, params)
          contract = contract.new query, current_user
          contract.validate

          query.user = current_user

          form_result query, form_representer, ::API::Errors::ErrorBase.create_errors(contract.errors)
        end

        def form_result(query, form_representer, api_errors)
          # errors for invalid data (e.g. validation errors) are handled inside the form
          if api_errors.all? { |error| error.code == 422 }
            status 200
            form_representer.new query, current_user: current_user, errors: api_errors
          else
            fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
          end
        end

        def create_query(request_body, current_user)
          rep = representer.new Query.new, current_user: current_user
          query = rep.from_hash request_body
          call = ::CreateQueryService.new(user: current_user).call query

          if call.success?
            representer.new call.result, current_user: current_user, embed_links: true
          else
            fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
          end
        end

        def update_query(query, request_body, current_user)
          rep = representer.new query, current_user: current_user
          query = rep.from_hash request_body
          call = ::UpdateQueryService.new(user: current_user).call query

          if call.success?
            representer.new call.result, current_user: current_user, embed_links: true
          else
            fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
          end
        end

        def representer
          ::API::V3::Queries::QueryRepresenter
        end

        ##
        # @param request [Grape::Request] Request from which to use the query params.
        def query_from_params(request, current_user:)
          params = ActionDispatch::Request.new(request.env).query_parameters
          query = Query.new_default

          UpdateQueryFromV3ParamsService.new(query, current_user).call(params)
          # the service mutates the given query in place so we just return it
          query
        end

        def update_query_from_body_and_params(query, body, params)
          representer = ::API::V3::Queries::QueryRepresenter.create query, current_user: current_user
          # Note that we do not deal with failures here. The query
          # needs to be validated later.
          UpdateQueryFromV3ParamsService.new(query, current_user).call(params)

          representer.from_hash Hash(body)
        end
      end
    end
  end
end
