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

# SQL builders for the FORM_CONFIGURATION aspect specifically: they key a custom_fields_types
# join through the type that owns a linked form configuration, and drop the custom fields its
# link chain excludes. Two shapes are offered — .remap rewrites an existing type-id column,
# .source_table emits a driving table over a given set of type ids.
#
# The resolution itself is generic and lives on Type (see the note above
# .effective_source_id_subquery in Type::ConfigurationLinkable); both shapes here delegate to
# Type.effective_configuration_join, so the chain is resolved inside the caller's query with no
# preceding round-trip and no window in which a link could change between resolving and using
# it. All this module adds on top is the aspect and the feature-flag gate — an equivalent for
# another aspect belongs in its own module rather than as a parameter here.
module Type::FormConfigurationSql
  EMPTY_ELEMENTS = "'{}'::text[]"

  module_function

  # [join_sql, type_id_expression, excluded_elements_expression] to remap an existing own
  # type-id column through the effective form source. +own_type_id_expr+ is the SQL for that
  # column at the call site, and must name a table joined before the returned fragment.
  #
  # With the variants feature off, ["", own_type_id_expr, EMPTY_ELEMENTS] so the original SQL
  # is emitted verbatim and the exclusion check is a no-op.
  def remap(own_type_id_expr)
    return ["", own_type_id_expr, EMPTY_ELEMENTS] unless resolve_in_sql?

    Type.effective_configuration_join(own_type_id_expr, aspect)
  end

  # [join_sql, type_id_expression, excluded_elements_expression] for a driving table over the
  # given type ids. Callers key their custom_fields_types join on the returned type-id
  # expression, filter it with Type.excluded_custom_field_condition, and may aggregate
  # wp_types.own_id to recover each work package's own type id.
  # +type_ids+ must be non-empty.
  def source_table(type_ids)
    values = type_ids.map { |id| "(#{id})" }.join(", ")
    driving_table = "JOIN (VALUES #{values}) AS wp_types(own_id) ON TRUE"
    return [driving_table, "wp_types.own_id", EMPTY_ELEMENTS] unless resolve_in_sql?

    join, source_id, excluded =
      Type.effective_configuration_join("wp_types.own_id", aspect,
                                        only_type_ids: type_ids)

    ["#{driving_table} #{join}", source_id, excluded]
  end

  def aspect
    Type::ConfigurationLink::FORM_CONFIGURATION
  end
  private_class_method :aspect

  def resolve_in_sql?
    OpenProject::FeatureDecisions.type_variants_active?
  end
  private_class_method :resolve_in_sql?
end
