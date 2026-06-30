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

class ResourceUserCard < PersistedView
  include ResourceManagement::Categorized

  # Ordered list of field identifiers shown on each user card. Built-in keys
  # ("department", "working_times") and custom field column names ("cf_<id>").
  store_attribute :options, :card_fields, :json, default: %w[department working_times]

  validate :query_must_be_user_query

  def results
    query = effective_query
    return if query.nil?

    query.results.in_project(project)
  end

  def manually_picked?
    effective_query&.manual_elements? || false
  end

  def build_default_query
    UserQuery.new(project:, principal:)
  end

  def apply_query_configuration(filters_json:, filter_mode:)
    query = effective_query
    return if query.nil?

    query.filters.clear

    if manual_mode?(filter_mode)
      query.manual_elements = true
    else
      query.manual_elements = false

      query.ordered_entities.destroy_all
      configure_automatic(query, filters_json)
    end
  end

  private

  def manual_mode?(filter_mode)
    filter_mode.to_s == "manual"
  end

  def configure_automatic(query, filters_json)
    parse_filters(filters_json).each do |filter|
      query.where(filter[:attribute], filter[:operator], filter[:values])
    end
  end

  def parse_filters(filters_json)
    return [] if filters_json.blank?

    ::Queries::ParamsParser::APIV3FiltersParser.parse(filters_json)
  rescue JSON::ParserError
    []
  end

  def query_must_be_user_query
    resolved = effective_query
    return if resolved.nil? || resolved.is_a?(UserQuery)

    errors.add(:query, :invalid)
  end
end
