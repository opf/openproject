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

module ResourcePlannerViews
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    # `filters` and `filter_mode` are not view attributes; pull them out before
    # `super` calls `model.attributes=`, then apply them to the query.
    def set_attributes(params)
      filters = params.delete(:filters)
      filter_mode = params.delete(:filter_mode)

      super

      configure_query(filters:, filter_mode:)
    end

    def set_default_attributes(_params)
      model.change_by_system do
        model.principal ||= user
      end
    end

    # Builds the query if missing and lets the view type translate the filter
    # selection and mode into query filters. Non-configurable view types are
    # left untouched.
    def configure_query(filters:, filter_mode:)
      return unless model.respond_to?(:apply_query_configuration)

      ensure_query
      return if model.query.nil?

      model.apply_query_configuration(filters_json: filters, filter_mode:)
    end

    def ensure_query
      return if model.query.present?

      query = model.build_default_query
      return if query.nil?

      # `query=` touches `query_id`/`query_type`; on create the model has been
      # extended with ChangedBySystem so the contract does not flag them as
      # user-written readonly attributes.
      if model.respond_to?(:change_by_system)
        model.change_by_system { model.query = query }
      else
        model.query = query
      end
    end
  end
end
