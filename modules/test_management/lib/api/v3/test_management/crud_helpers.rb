# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module TestManagement
      module CrudHelpers
        def request_body
          raw = env["api.request.body"]
          raw = params.to_h if raw.blank?
          raw.respond_to?(:to_h) ? raw.to_h.stringify_keys : {}
        end

        def attributes_from(map, body = request_body)
          map.each_with_object({}) do |(key, attribute), attributes|
            attributes[attribute] = body[key] if body.key?(key)
          end
        end

        def allowed_any?(permissions, project)
          permissions.any? { |permission| current_user.allowed_in_project?(permission, project) }
        end

        def ensure_success!(call) # rubocop:disable Metrics/AbcSize
          return if call.success?

          symbols = call.errors.details[:base].pluck(:error)
          raise ::API::Errors::Unauthorized if symbols.intersect?(%i[error_unauthorized tm_ci_disabled])

          conflict = %i[tm_invalid_transition tm_run_finished]
          if symbols.intersect?(conflict)
            raise ::API::Errors::Conflict.new(message: call.errors.full_messages.join(" "))
          end

          raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" "))
        end

        def respond_with_call!(call, representer, status_code: 200, **)
          ensure_success!(call)
          status status_code
          representer.new(call.result.reload, current_user:, **)
        end

        def respond_deleted!(call)
          ensure_success!(call)
          status 204
          body false
        end

        def offset_page_params
          { page: params[:offset], per_page: params[:pageSize] }
        end

        def unpaginated_collection(element_decorator, models, **)
          collection_class(::API::Decorators::UnpaginatedCollection, element_decorator).new(models, current_user:, **)
        end

        def paginated_collection(element_decorator, models, **)
          collection_class(::API::Decorators::OffsetPaginatedCollection, element_decorator)
            .new(models, current_user:, **)
        end

        def collection_class(base, element_decorator)
          @tm_collection_classes ||= {}
          @tm_collection_classes[[base, element_decorator]] ||= Class.new(base) { element_decorator element_decorator }
        end
      end
    end
  end
end
