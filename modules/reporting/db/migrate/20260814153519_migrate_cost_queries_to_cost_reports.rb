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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Converts the saved cost reports from the cost_queries table into a
# CostReportQuery (the definition) plus a CostReport (its presentation).
#
# The old ids are not preserved, so links to a saved report have to be recreated.
# The cost_queries table is left in place and can be dropped in a later release.
class MigrateCostQueriesToCostReports < ActiveRecord::Migration[8.1]
  # Filters and group bys the engine injects itself. They are serialized as part
  # of the chain but are not part of the user's definition.
  SYSTEM_FILTERS = %w[PermissionFilter NoFilter].freeze
  SYSTEM_GROUP_BYS = %w[SingletonValue].freeze

  CUSTOM_FIELD = /\ACustomField(\d+)\z/

  PERMITTED_YAML_CLASSES = [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess].freeze

  # Local models, so that the migration does not depend on the real ones, whose
  # serialization and validations are free to change.
  class CostQuery < ApplicationRecord
    self.table_name = "cost_queries"
  end

  # The type column is written directly rather than through single table
  # inheritance, so that the migration does not have to know the classes.
  class PersistedQuery < ApplicationRecord
    self.table_name = "persisted_queries"
    self.inheritance_column = nil
  end

  class PersistedView < ApplicationRecord
    self.table_name = "persisted_views"
    self.inheritance_column = nil
  end

  def up
    CostQuery.order(:id).find_each do |cost_query|
      definition = deserialize(cost_query.serialized)

      if definition.nil?
        say "Skipping cost query #{cost_query.id} (#{cost_query.name}): unreadable definition"
        next
      end

      rows, columns = axes(definition)

      query = create_query(cost_query, definition, rows, columns)
      create_view(cost_query, query, rows, columns)
    end
  end

  def down
    PersistedView.where(type: "CostReport").delete_all
    PersistedQuery.where(type: "CostReportQuery").delete_all
  end

  private

  def create_query(cost_query, definition, rows, columns)
    PersistedQuery.create!(
      type: "CostReportQuery",
      project_id: cost_query.project_id,
      principal_id: cost_query.user_id,
      filters: filters(definition),
      # Columns before rows, matching the order the engine expects them in.
      group_bys: columns + rows,
      selects: [],
      orders: [],
      created_at: cost_query.created_at,
      updated_at: cost_query.updated_at
    )
  end

  def create_view(cost_query, query, rows, columns)
    PersistedView.create!(
      type: "CostReport",
      name: cost_query.name,
      project_id: cost_query.project_id,
      principal_id: cost_query.user_id,
      query_type: "PersistedQuery",
      query_id: query.id,
      public: cost_query.is_public,
      category: "cost_report",
      options: { "pivot_rows" => rows,
                 "pivot_columns" => columns,
                 "legacy_cost_query_id" => cost_query.id },
      created_at: cost_query.created_at,
      updated_at: cost_query.updated_at
    )
  end

  def deserialize(serialized)
    definition = YAML.safe_load(serialized.to_s, permitted_classes: PERMITTED_YAML_CLASSES, aliases: true)

    definition if definition.is_a?(Hash)
  rescue Psych::Exception
    nil
  end

  def filters(definition)
    Array(definition[:filters]).filter_map do |name, options|
      next if SYSTEM_FILTERS.include?(name)

      options ||= {}
      operator = options[:operator].to_s
      next if operator.empty?

      { "attribute" => attribute_for(name),
        "operator" => operator,
        "values" => Array(options[:values]) }
    end
  end

  # Returns the row and column dimensions, each in the order the user sees them.
  #
  # The serialized group bys are stored in reverse chain order (see
  # CostQuery#serialize), and within an axis the chain order is the order the
  # user arranged them in.
  def axes(definition)
    dimensions = Array(definition[:group_bys]).reverse.filter_map do |name, options|
      next if SYSTEM_GROUP_BYS.include?(name)

      # The engine defaults a group by without a type to a column.
      [attribute_for(name), (options || {})[:type].to_s]
    end

    rows, columns = dimensions.partition { |_attribute, type| type == "row" }

    [rows.map(&:first), columns.map(&:first)]
  end

  # The engine names its classes after the attribute, e.g. WorkPackageId, and its
  # custom field classes after the custom field id, e.g. CustomField7.
  def attribute_for(name)
    match = CUSTOM_FIELD.match(name.to_s)

    if match
      "cf_#{match[1]}"
    else
      name.to_s.underscore
    end
  end
end
