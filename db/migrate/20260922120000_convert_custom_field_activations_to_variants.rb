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

# The previous project custom field configuration table custom_fields_projects
# is converted to become a type variant.
# We only need to convert the active form attributes, since that is what the other table controls.
#
# If this configuration is only ever found once, it's a project-specific variant.
# If a second project uses the same configuration, we use a global variant instead.
#
# For the project admin, no visible changes except for the UI changing.
# custom_fields_projects table is kept to have a record of the previous data. It is dropped later.
# https://community.openproject.org/projects/AUTOWORK/work_packages/AUTOWORK-310/activity
class ConvertCustomFieldActivationsToVariants < ActiveRecord::Migration[8.0]
  ASPECTS = %w[pdf_export defaults workflows form_configuration project_attributes].freeze

  NAME_BUDGET = 100
  NAME_LIMIT = 255

  def up
    shapes = collect_shapes
    return if shapes.empty?

    name_shapes(shapes)
    create_variants(shapes)
    repoint_project_types(shapes)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def collect_shapes
    grouped = select_all(narrowed_fields_sql).to_a.group_by do |row|
      [row["type_id"], row["source_id"], row["custom_field_ids"]]
    end

    grouped.map { |key, rows| shape_from(key, rows) }
           .sort_by { |shape| [shape[:type_id], shape[:custom_field_ids]] }
  end

  def shape_from((type_id, source_id, custom_field_ids), rows)
    projects = rows.pluck("project_id").uniq.map(&:to_i)
    field_ids = custom_field_ids.split(",").map(&:to_i)

    {
      type_id: type_id.to_i,
      source_id: source_id.to_i,
      custom_field_ids: field_ids,
      type_name: rows.first["type_name"],
      field_names: rows.pluck("custom_field_name").uniq,
      excluded_elements: field_ids.map { "custom_field_#{it}" },
      owner_id: (projects.first if projects.one?),
      project_ids: projects
    }
  end

  # A field counts as switched off if the project does not list it in the custom_fields_projects table.
  # Custom fields with "is_for_all" set are excluded here, as they are always active.
  def narrowed_fields_sql
    <<~SQL.squish
      SELECT pt.project_id,
             pt.type_id,
             pt.variant_id AS source_id,
             t.name AS type_name,
             cf.name AS custom_field_name,
             string_agg(cf.id::text, ',') OVER (
               PARTITION BY pt.project_id, pt.type_id ORDER BY cf.id
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
             ) AS custom_field_ids
      FROM project_types pt
      JOIN types t ON t.id = pt.type_id
      JOIN type_variants applied ON applied.id = pt.variant_id
      JOIN custom_fields_types cft
        ON cft.type_variant_id = COALESCE(applied.form_configuration_source_id, applied.id)
      JOIN custom_fields cf ON cf.id = cft.custom_field_id
      WHERE cf.is_for_all = FALSE
        AND NOT ('custom_field_' || cf.id = ANY (applied.form_configuration_excluded_elements))
        AND NOT EXISTS (
          SELECT 1 FROM custom_fields_projects cfp
          WHERE cfp.custom_field_id = cf.id AND cfp.project_id = pt.project_id
        )
      ORDER BY pt.type_id, cf.name, cf.id, pt.project_id
    SQL
  end

  def name_shapes(shapes)
    taken = Hash.new { |names, type_id| names[type_id] = [] }

    shapes.each do |shape|
      shape[:variant_name] = unique_name(shape, taken[shape[:type_id]])
      taken[shape[:type_id]] << shape[:variant_name].downcase
    end
  end

  def unique_name(shape, taken)
    kept = budgeted_field_count(shape)
    kept += 1 while taken.include?(variant_name(shape, kept).downcase) && kept < shape[:field_names].size

    add_trailing_counter(variant_name(shape, kept), taken)
  end

  def budgeted_field_count(shape)
    count = shape[:field_names].size
    count -= 1 while count > 1 && variant_name(shape, count).length > NAME_BUDGET
    count
  end

  def variant_name(shape, kept)
    fields = shape[:field_names]
    listed = fields.take(kept).join(", ")
    remaining = fields.size - kept

    if remaining.zero?
      translate("variant_name", type: shape[:type_name], fields: listed)
    else
      translate("variant_name_truncated", type: shape[:type_name], fields: listed, count: remaining)
    end
  end

  def add_trailing_counter(name, taken)
    name = name[0, NAME_LIMIT]
    return name unless taken.include?(name.downcase)

    counter = 2
    counter += 1 while taken.include?(numbered(name, counter).downcase)
    numbered(name, counter)
  end

  def numbered(name, counter)
    suffix = " (#{counter})"
    "#{name[0, NAME_LIMIT - suffix.length]}#{suffix}"
  end

  def create_variants(shapes)
    columns = ASPECTS.map { "#{it}_source_id" }.join(", ")

    shapes.each { it[:variant_id] = insert_variant(it, columns).to_i }
  end

  # Reuse every aspect including workflows and forms
  # TODO this will change when named forms and workflows are introduced
  def insert_variant(shape, columns)
    source = sql_value(shape[:source_id])
    sources = ([source] * ASPECTS.size).join(", ")

    select_value(<<~SQL.squish)
      INSERT INTO type_variants
        (type_id, project_id, variant_name, is_default_variant, enabled_in_new_projects,
         #{columns}, form_configuration_excluded_elements, workflow_id, created_at, updated_at)
      VALUES (#{sql_value(shape[:type_id])}, #{sql_value(shape[:owner_id])}, #{sql_value(shape[:variant_name])},
              FALSE, FALSE, #{sources}, #{array_literal(shape[:excluded_elements])},
              (SELECT workflow_id FROM type_variants WHERE id = #{source}), NOW(), NOW())
      RETURNING id
    SQL
  end

  def repoint_project_types(shapes)
    pairs = shapes.flat_map do |shape|
      shape[:project_ids].map { [it, shape[:type_id], shape[:variant_id]] }
    end

    pairs.each_slice(1_000) do |slice|
      execute(<<~SQL.squish)
        UPDATE project_types pt
        SET variant_id = m.variant_id::bigint, updated_at = NOW()
        FROM (VALUES #{slice.map { row_literal(it) }.join(', ')})
          AS m (project_id, type_id, variant_id)
        WHERE pt.project_id = m.project_id::bigint AND pt.type_id = m.type_id::bigint
      SQL
    end
  end

  def row_literal(values) = "(#{values.map { sql_value(it) }.join(', ')})"

  def sql_value(value) = value.nil? ? "NULL" : ActiveRecord::Base.connection.quote(value)

  def array_literal(elements) = "ARRAY[#{elements.map { sql_value(it) }.join(', ')}]::text[]"

  def translate(key, **)
    I18n.t("types.migration.#{key}", locale: default_language, **)
  end

  # Settings may be unavailable when migrating a clean database, so fall back to English.
  def default_language
    Setting.default_language.presence || "en"
  rescue StandardError
    "en"
  end
end
