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
# join through the variant that owns a linked form configuration, and drop the custom fields its
# link chain excludes. Two shapes are offered — .remap rewrites an existing variant-id column,
# .source_table emits a driving table over a given set of type ids.
#
# The resolution itself is generic and lives on TypeVariant (see the note above
# .effective_source_id_subquery in TypeVariant::ConfigurationLinkable); both shapes here delegate to
# TypeVariant.effective_configuration_join, so the chain is resolved inside the caller's query with no
# preceding round-trip and no window in which a link could change between resolving and using
# it. All this module adds on top is the aspect — an equivalent for another aspect belongs in
# its own module rather than as a parameter here.
module TypeVariant::FormConfigurationSql
  module_function

  # [join_sql, variant_id_expression, excluded_elements_expression] to remap an existing own
  # variant-id column through the effective form source. +own_variant_id_expr+ is the SQL for that
  # column at the call site, and must name a table joined before the returned fragment.
  def remap(own_variant_id_expr)
    TypeVariant.effective_configuration_join(own_variant_id_expr, aspect)
  end

  # [join_sql, variant_id_expression, excluded_elements_expression] for a driving table over the
  # given type ids. Callers key their custom_fields_types join on the returned variant-id
  # expression, filter it with Type.excluded_custom_field_condition, and may aggregate
  # wp_variants.own_id to recover each work package's own type id.
  # +variant_ids+ must be non-empty.
  def source_table(variant_ids)
    values = variant_ids.map { |id| "(#{id})" }.join(", ")
    driving_table = "JOIN (VALUES #{values}) AS wp_variants(own_id) ON TRUE"
    join, source_id, excluded =
      TypeVariant.effective_configuration_join("wp_variants.own_id", aspect,
                                               only_variant_ids: variant_ids)

    ["#{driving_table} #{join}", source_id, excluded]
  end

  def aspect
    TypeVariant::FORM_CONFIGURATION
  end
  private_class_method :aspect
end
