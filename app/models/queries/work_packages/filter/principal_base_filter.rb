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

class Queries::WorkPackages::Filter::PrincipalBaseFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::WorkPackages::Filter::MeValueFilterMixin

  def allowed_values
    @allowed_values ||= me_allowed_value + principal_loader.principal_values
  end

  def available?
    User.current.logged? || allowed_values.any?
  end

  def ar_object_filter?
    true
  end

  def where
    operator_strategy.sql_for_field(values_replaced, self.class.model.table_name, key)
  end

  # `allowed_values` only carries ids, not labels, so an inline `<select>` would
  # render blank entries. Render a server-side autocompleter instead, scoped to
  # the same candidate set `allowed_values` accepts.
  def autocomplete_options
    {
      component: "opce-user-autocompleter",
      resource: "principals",
      url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
      searchKey: "any_name_attribute",
      filters: autocomplete_filters,
      additionalOptions: me_autocomplete_options,
      model: autocomplete_model,
      hideSelected: true,
      defaultData: false
    }
  end

  private

  def autocomplete_filters
    filters = []
    filters << { name: "type", operator: "=", values: autocomplete_principal_types } if autocomplete_principal_types
    filters << { name: "member", operator: "=", values: [project.id.to_s] } if project
    filters
  end

  # `nil` advertises every principal type, matching the API's default scope.
  def autocomplete_principal_types
    nil
  end

  def me_autocomplete_options
    return [] unless User.current.logged?

    [{ id: me_value_key, name: me_label }]
  end

  # Preselected values are resolved here rather than by the autocompleter, which
  # would try to `GET /api/v3/principals/me` for the me value.
  #
  # `opce-user-autocompleter` identifies items by `href` and `name`, so an item
  # has to be shaped exactly like the one the principals API returns for it.
  # Otherwise the fetched item is not recognized as the selected one and can be
  # picked a second time. The me value carries no `href` on either side.
  def autocomplete_model
    value_objects.map do |object|
      { id: object.id.to_s, name: object.name, href: autocomplete_href(object) }.compact
    end
  end

  def autocomplete_href(object)
    return if object.is_a?(::Queries::Filters::MeValue)

    ::API::V3::Utilities::PathHelper::ApiV3Path
      .public_send(::API::V3::Principals::PrincipalType.for(object), object.id)
  end

  def principal_loader
    @principal_loader ||= ::Queries::WorkPackages::Filter::PrincipalLoader.new(project)
  end
end
