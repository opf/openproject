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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module FormConfiguration
    module EmbeddedQueryBuilder
      module_function

      def build(query_props:, name:, user:)
        query = Query.new_default(name:)
        query.filters = []
        assign_system_user(query)

        query_call = ::API::V3::UpdateQueryFromV3ParamsService
          .new(query, user)
          .call(query_parameters(query_props), valid_subset: true)

        return query_call if query_call.failure?

        query.show_hierarchies = false
        query_call
      rescue JSON::ParserError
        invalid_query_result
      end

      def rebuild(query:, user:)
        return invalid_query_result if query.nil?

        build(
          query_props: ::API::V3::Queries::QueryParamsRepresenter.new(query).to_h,
          name: query.name,
          user:
        )
      end

      def query_parameters(query_props)
        return {} if query_props.blank?
        if query_props.is_a?(String)
          return JSON.parse(query_props).deep_symbolize_keys
        end

        params = query_props.respond_to?(:to_unsafe_h) ? query_props.to_unsafe_h : query_props
        params.deep_symbolize_keys
      end

      def assign_system_user(query)
        query.extend(OpenProject::ChangedBySystem)
        query.change_by_system { query.user = User.system }
      end

      def invalid_query_result
        errors = Query.new.errors
        errors.add(:base, I18n.t("types.edit.form_configuration.invalid_query"))

        ServiceResult.failure(errors:)
      end
    end
  end
end
