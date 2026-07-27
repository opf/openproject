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

# SQL builders that key a custom_fields_types join through the type that owns a
# linked form configuration, resolving links via Type#effective_source_for so
# the flag gate and cycle tolerance live in one place. Two shapes are offered:
# one remaps an existing type-id column, the other emits a driving table over a
# given set of type ids.
module Type::EffectiveSourceSql
  module_function

  # [join_sql, type_id_expression] to remap an existing own type-id column
  # through the effective form source. +own_type_id_expr+ is the SQL for that
  # column at the call site. Empty map ⇒ ["", own_type_id_expr] so the original
  # SQL is emitted verbatim.
  def form_configuration_remap(own_type_id_expr)
    map = form_configuration_map
    return ["", own_type_id_expr] if map.empty?

    values = map.map { |own_id, source_id| "(#{own_id}, #{source_id})" }.join(", ")
    join = "LEFT JOIN (VALUES #{values}) AS effective(type_id, source_id) " \
           "ON effective.type_id = #{own_type_id_expr}"
    [join, "COALESCE(effective.source_id, #{own_type_id_expr})"]
  end

  # SQL fragment joining a driving (own_id, source_id) table for the given type
  # ids, each mapped to its effective form source (identity when unlinked).
  # Callers key their custom_fields_types join on wp_types.source_id and may
  # aggregate wp_types.own_id to recover each work package's own type id.
  # +type_ids+ must be non-empty.
  def form_configuration_source_table(type_ids)
    map = form_configuration_map
    values = type_ids.map { |id| "(#{id}, #{map.fetch(id, id)})" }.join(", ")
    "JOIN (VALUES #{values}) AS wp_types(own_id, source_id) ON TRUE"
  end

  # Maps each type linking its form configuration to the id of the type that
  # owns it, excluding identity; empty (identity everywhere) when the variants
  # feature is off or no links exist.
  def form_configuration_map
    return {} unless OpenProject::FeatureDecisions.type_variants_active?

    aspect = Type::ConfigurationLink::FORM_CONFIGURATION
    linked_type_ids = Type::ConfigurationLink.where(aspect:).distinct.pluck(:type_id)

    Type.with_effective_configuration(aspect)
        .where(id: linked_type_ids)
        .to_h { |type| [type.id, type.effective_source_id(aspect)] }
        .reject { |own_id, source_id| own_id == source_id }
  end
  private_class_method :form_configuration_map
end
