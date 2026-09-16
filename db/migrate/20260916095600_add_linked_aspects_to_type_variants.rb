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

# Each aspect's chain is followed to the variant that owns it.
# When that owner is the variant's own base, the aspect gets linked to its parent.
# When it is anything else the owner's configuration is copied onto the variant and it stays independent.
#
# NOTE: Only a variant's own '<aspect>_excluded_elements' survives. Fields hidden at an
# intermediate hop of a multi-hop chain are ignored and will reappear.
class AddLinkedAspectsToTypeVariants < ActiveRecord::Migration[8.1]
  ASPECTS = %w[pdf_export defaults workflows form_configuration project_attributes].freeze

  COPY_PLAN = {
    "pdf_export" => { own_columns: %w[pdf_export_templates_config] },
    "defaults" => { own_columns: %w[patterns default_work_package_description] },
    "workflows" => { child_table: "workflows",
                     child_fields: %w[old_status_id new_status_id role_id assignee author] },
    "form_configuration" => { own_columns: %w[attribute_groups required_attributes],
                              child_table: "custom_fields_types",
                              child_fields: %w[custom_field_id] },
    "project_attributes" => { child_table: "project_custom_field_type_mappings",
                              child_fields: %w[custom_field_id created_at updated_at] }
  }.freeze

  class MigratedTypeVariant < ActiveRecord::Base
    self.table_name = "type_variants"
  end

  def up
    add_column :type_variants, :linked_aspects, :text, array: true, null: false, default: []

    ASPECTS.each { |aspect| backfill(aspect) }
  end

  def down
    remove_column :type_variants, :linked_aspects
  end

  private

  def backfill(aspect)
    variants = MigratedTypeVariant.all.index_by(&:id)
    default_variants = variants.values.select(&:is_default_variant).index_by(&:type_id)

    variants.each_value do |variant|
      owner = owner_of(variant, aspect, variants)
      next if owner == variant # already owns the aspect, nothing to change

      if owner == default_variants[variant.type_id]
        variant.update!(linked_aspects: variant.linked_aspects + [aspect])
      else
        copy_aspect(aspect, source: owner, target: variant)
      end
    end
  end

  def owner_of(variant, aspect, variants)
    loop do
      source_id = variant["#{aspect}_source_id"]
      break if source_id.nil?

      variant = variants.fetch(source_id)
    end
    variant
  end

  def copy_aspect(aspect, source:, target:)
    plan = COPY_PLAN.fetch(aspect)
    target.update!(plan[:own_columns].index_with { |column| source[column] }) if plan[:own_columns]
    copy_child_rows(plan[:child_table], plan[:child_fields], source, target) if plan[:child_table]
  end

  def copy_child_rows(table, fields, source, target)
    list = fields.join(", ")
    execute <<~SQL.squish
      INSERT INTO #{table} (#{list}, type_variant_id)
      SELECT #{list}, #{target.id} FROM #{table} WHERE type_variant_id = #{source.id}
      ON CONFLICT DO NOTHING
    SQL
  end
end
