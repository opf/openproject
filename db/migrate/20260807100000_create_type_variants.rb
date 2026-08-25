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

require Rails.root.join("db/migrate/migration_utils/utils")

# Historically, all attributes of a type were embedded there except for workflows.
# For variants, we would copy a lot of the information, but still hide the type id and use its parent.
# This caused a lot of problems down the road.
#
# This migration introduces a TypeVariant model that takes care of default and variant configurations of a type.
class CreateTypeVariants < ActiveRecord::Migration[8.0]
  include Migration::Utils

  ASPECTS = %w[pdf_export defaults workflows form_configuration project_attributes].freeze

  # Only these two aspects are lists a variant can remove fields in
  EXCLUDABLE_ASPECTS = %w[form_configuration project_attributes].freeze

  # Mapping for types => type_variants column name.
  # We also rename description to make it clearer it's the default WP description
  CONFIGURATION_COLUMNS = {
    "attribute_groups" => "attribute_groups",
    "description" => "default_work_package_description",
    "is_default" => "enabled_in_new_projects",
    "patterns" => "patterns",
    "pdf_export_templates_config" => "pdf_export_templates_config"
  }.freeze

  def up
    create_type_variants
    backfill_variants
    migrate_configuration_links
    # Type configuration links have migrated, need to drop now to prevent FK constraints
    drop_table :type_configuration_links
    repoint_workflows
    repoint_custom_fields_types
    repoint_project_custom_field_type_mappings
    repoint_project_types
    drop_variant_types
    drop_legacy_tables
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def create_type_variants
    define_type_variants_table
    add_type_variants_constraints
  end

  def define_type_variants_table
    create_table :type_variants do |t|
      t.references :type, null: false, foreign_key: { on_delete: :cascade }
      # Unused as yet: project specific variants land in the next step, and the column is here
      # so this table is not rewritten for them.
      t.references :project, null: true, foreign_key: { on_delete: :cascade }
      t.string :variant_name
      t.boolean :is_default_variant, null: false, default: false
      t.boolean :enabled_in_new_projects, null: false, default: false

      t.text :attribute_groups
      t.text :default_work_package_description
      t.text :patterns
      t.jsonb :pdf_export_templates_config, default: {}

      ASPECTS.each do |aspect|
        t.bigint :"#{aspect}_source_id"

        if EXCLUDABLE_ASPECTS.include?(aspect)
          t.text :"#{aspect}_excluded_elements", array: true, null: false, default: []
        end
      end

      # Temporary field to be dropped again at the end of this migration.
      t.bigint :legacy_type_id

      t.timestamps
    end
  end

  def add_type_variants_constraints
    ASPECTS.each do |aspect|
      add_foreign_key :type_variants, :type_variants, column: :"#{aspect}_source_id", on_delete: :restrict
      add_index :type_variants, :"#{aspect}_source_id"
    end

    add_index :type_variants, :legacy_type_id

    # A base variant is exactly the one without a name, so add a constraint to make sure.
    add_check_constraint :type_variants,
                         "is_default_variant = (variant_name IS NULL)",
                         name: "type_variants_base_has_no_name"

    add_index :type_variants, :type_id,
              unique: true,
              where: "is_default_variant",
              name: "index_type_variants_one_base_per_type"

    add_index :type_variants, :type_id,
              unique: true,
              where: "enabled_in_new_projects",
              name: "index_type_variants_one_new_project_default_per_type"

    add_index :type_variants, "type_id, lower(variant_name)",
              unique: true,
              where: "variant_name IS NOT NULL",
              name: "index_type_variants_on_type_id_and_LOWER_variant_name"
  end

  def backfill_variants
    source_columns = CONFIGURATION_COLUMNS.keys.join(", ")
    target_columns = CONFIGURATION_COLUMNS.values.join(", ")

    # A root type's own configuration becomes its base variant.
    execute <<~SQL.squish
      INSERT INTO type_variants
        (type_id, variant_name, is_default_variant, #{target_columns}, legacy_type_id, created_at, updated_at)
      SELECT id, NULL, true, #{source_columns}, id, now(), now()
      FROM types
      WHERE parent_id IS NULL
    SQL

    # Each variant type becomes a named variant of the type it was based off.
    execute <<~SQL.squish
      INSERT INTO type_variants
        (type_id, variant_name, is_default_variant, #{target_columns}, legacy_type_id, created_at, updated_at)
      SELECT parent_id, name, false, #{source_columns}, id, now(), now()
      FROM types
      WHERE parent_id IS NOT NULL
    SQL
  end

  # Each (type, aspect) link row becomes the matching columns on the variant
  def migrate_configuration_links
    ASPECTS.each do |aspect|
      assignments = ["#{aspect}_source_id = source.id"]
      assignments << "#{aspect}_excluded_elements = l.excluded_elements" if EXCLUDABLE_ASPECTS.include?(aspect)

      execute <<~SQL.squish
        UPDATE type_variants v
        SET #{assignments.join(', ')}
        FROM type_configuration_links l
        JOIN type_variants source ON source.legacy_type_id = l.source_id
        WHERE v.legacy_type_id = l.type_id
          AND l.aspect = #{quote(aspect)}
      SQL
    end
  end

  def repoint_workflows
    remove_index_on :workflows, "wkfs_role_type_old_status", %w[role_id type_id old_status_id]
    move_type_reference :workflows
    add_index :workflows, %i[role_id type_variant_id old_status_id], name: "wkfs_role_type_variant_old_status"
  end

  def repoint_custom_fields_types
    remove_index_on :custom_fields_types, "custom_fields_types_unique", %w[custom_field_id type_id]
    move_type_reference :custom_fields_types
    add_index :custom_fields_types, %i[custom_field_id type_variant_id],
              unique: true, name: "custom_fields_types_unique"
  end

  def repoint_project_custom_field_type_mappings
    remove_index_on :project_custom_field_type_mappings,
                    "index_project_custom_field_type_mappings_unique",
                    %w[type_id custom_field_id]
    move_type_reference :project_custom_field_type_mappings
    add_index :project_custom_field_type_mappings, %i[type_variant_id custom_field_id],
              unique: true, name: "index_project_custom_field_type_mappings_unique"
  end

  # Replace type_id for the type_variant_id of the variant that type became
  def move_type_reference(table)
    add_column table, :type_variant_id, :bigint

    execute <<~SQL.squish
      UPDATE #{table} t
      SET type_variant_id = v.id
      FROM type_variants v
      WHERE v.legacy_type_id = t.type_id
    SQL

    change_column_null table, :type_variant_id, false
    remove_column table, :type_id
    add_foreign_key table, :type_variants, column: :type_variant_id, on_delete: :cascade
    add_index table, :type_variant_id
  end

  # variant_id stops being a type, and instead a variant_id we created above.
  def repoint_project_types
    remove_foreign_key :project_types, column: :variant_id

    execute <<~SQL.squish
      UPDATE project_types pt
      SET variant_id = v.id
      FROM type_variants v
      WHERE v.legacy_type_id = COALESCE(pt.variant_id, pt.type_id)
    SQL

    change_column_null :project_types, :variant_id, false
    add_foreign_key :project_types, :type_variants, column: :variant_id, on_delete: :restrict
  end

  def drop_variant_types
    # A custom action naming a variant has nothing to target once variants stop being types.
    execute <<~SQL.squish
      DELETE FROM custom_actions_types
      WHERE type_id IN (SELECT id FROM types WHERE parent_id IS NOT NULL)
    SQL

    # Change journals to target the parent type_id now that old  variant types are removed
    execute <<~SQL.squish
      UPDATE work_package_journals j
      SET type_id = t.parent_id
      FROM types t
      WHERE t.id = j.type_id AND t.parent_id IS NOT NULL
    SQL

    execute "DELETE FROM types WHERE parent_id IS NOT NULL"

    remove_index_on :types, "index_types_on_LOWER_name_and_parent_id"
    remove_column :types, :parent_id
    remove_column :types, :is_standard
    add_index :types, "lower(name)", unique: true, name: "index_types_on_LOWER_name"

    CONFIGURATION_COLUMNS.each_key { |column| remove_column :types, column }
  end

  def drop_legacy_tables
    remove_column :type_variants, :legacy_type_id

    # Superseded by project_types table in 20260804123419
    drop_table :projects_types
  end
end
