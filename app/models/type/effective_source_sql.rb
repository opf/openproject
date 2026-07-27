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

# SQL builders that key a custom_fields_types join through the type that owns a linked form
# configuration, and drop the custom fields its link chain excludes. Both shapes resolve the
# chain inside the caller's query via Type.effective_configuration_lateral — no preceding
# round-trip, and no window in which a link could change between resolving and using it.
# Two shapes are offered: one remaps an existing type-id column, the other emits a driving
# table over a given set of type ids. This module only adds the form-configuration aspect and
# the flag gate on top.
module Type::EffectiveSourceSql
  EMPTY_ELEMENTS = "'{}'::text[]"
  CUSTOM_FIELD_ELEMENT_PREFIX = "custom_field_"

  module_function

  # [join_sql, type_id_expression, excluded_elements_expression] to remap an existing own
  # type-id column through the effective form source. +own_type_id_expr+ is the SQL for that
  # column at the call site, and must name a table joined before the returned fragment.
  #
  # With the variants feature off, ["", own_type_id_expr, EMPTY_ELEMENTS] so the original SQL
  # is emitted verbatim and the exclusion check is a no-op.
  def form_configuration_remap(own_type_id_expr)
    return ["", own_type_id_expr, EMPTY_ELEMENTS] unless resolve_in_sql?

    Type.effective_configuration_lateral(own_type_id_expr, form_configuration_aspect)
  end

  # [join_sql, type_id_expression, excluded_elements_expression] for a driving table over the
  # given type ids. Callers key their custom_fields_types join on the returned type-id
  # expression, filter it with .excluded_element_condition, and may aggregate wp_types.own_id
  # to recover each work package's own type id.
  # +type_ids+ must be non-empty.
  def form_configuration_source_table(type_ids)
    values = type_ids.map { |id| "(#{id})" }.join(", ")
    driving_table = "JOIN (VALUES #{values}) AS wp_types(own_id) ON TRUE"
    return [driving_table, "wp_types.own_id", EMPTY_ELEMENTS] unless resolve_in_sql?

    join, source_id, excluded =
      Type.effective_configuration_lateral("wp_types.own_id", form_configuration_aspect)

    ["#{driving_table} #{join}", source_id, excluded]
  end

  # Condition keeping only custom fields the chain does not exclude. Custom fields are
  # excluded under CustomField#attribute_name, so the id is keyed back into that form
  # rather than compared numerically.
  #
  # `<> ALL` over an empty array is TRUE, which is what makes the flag-off case above a
  # no-op instead of something callers have to branch on.
  def excluded_element_condition(custom_field_id_expr, excluded_expr)
    "('#{CUSTOM_FIELD_ELEMENT_PREFIX}' || #{custom_field_id_expr}) <> ALL (#{excluded_expr})"
  end

  def form_configuration_aspect
    Type::ConfigurationLink::FORM_CONFIGURATION
  end
  private_class_method :form_configuration_aspect

  def resolve_in_sql?
    OpenProject::FeatureDecisions.type_variants_active?
  end
  private_class_method :resolve_in_sql?
end
