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

class ExtractNamedForms < ActiveRecord::Migration[8.1]
  include Migration::Utils

  def up
    create_form_configurations
    create_a_form_for_each_owner
    point_linked_variants_at_their_base_form
    flatten_required_attributes
    rekey_custom_fields_types

    execute <<~SQL.squish
      UPDATE type_variants
      SET linked_aspects = array_remove(linked_aspects, 'form_configuration')
    SQL

    remove_form_columns_from_type_variants
  end

  def down
    restore_form_columns_on_type_variants
    restore_custom_fields_types

    remove_foreign_key :type_variants, column: :form_configuration_id
    remove_index :type_variants, :form_configuration_id
    remove_column :type_variants, :form_configuration_id

    drop_table :form_configurations
  end

  private

  def linked(table) = "'form_configuration' = ANY(#{table}.linked_aspects)"

  def create_form_configurations
    create_table :form_configurations do |t|
      t.string :name, null: false
      t.text :description
      t.text :attribute_groups
      t.timestamps
    end

    add_index :form_configurations, "lower(name)", unique: true, name: "index_form_configurations_on_LOWER_name"
    add_column :type_variants, :form_configuration_id, :bigint
  end

  def create_a_form_for_each_owner
    say_with_time "Create a form for each variant that owns its form configuration" do
      execute <<~SQL.squish
        UPDATE type_variants
        SET form_configuration_id = nextval('form_configurations_id_seq')
        WHERE NOT #{linked('type_variants')}
      SQL

      execute <<~SQL.squish
        INSERT INTO form_configurations (id, name, attribute_groups, created_at, updated_at)
        SELECT id,
               CASE WHEN position = 1 THEN name ELSE name || ' (' || position || ')' END,
               attribute_groups,
               NOW(),
               NOW()
        FROM (
          SELECT v.form_configuration_id AS id,
                 v.attribute_groups,
                 named.name,
                 ROW_NUMBER() OVER (PARTITION BY LOWER(named.name) ORDER BY v.id) AS position
          FROM type_variants v
          INNER JOIN types t ON t.id = v.type_id
          CROSS JOIN LATERAL (
            SELECT CASE
                     WHEN v.is_default_variant THEN t.name
                     ELSE t.name || ': ' || v.variant_name
                   END || ' form' AS name
          ) named
          WHERE NOT #{linked('v')}
        ) owners
      SQL
    end
  end

  def point_linked_variants_at_their_base_form
    say_with_time "Point inheriting variants at their type's form" do
      execute <<~SQL.squish
        UPDATE type_variants v
        SET form_configuration_id = base.form_configuration_id
        FROM type_variants base
        WHERE base.type_id = v.type_id
          AND base.is_default_variant
          AND #{linked('v')}
      SQL
    end

    change_column_null :type_variants, :form_configuration_id, false
    add_index :type_variants, :form_configuration_id
    add_foreign_key :type_variants, :form_configurations, column: :form_configuration_id, on_delete: :restrict
  end

  def flatten_required_attributes
    say_with_time "Give inheriting variants their own required attributes" do
      execute <<~SQL.squish
        UPDATE type_variants v
        SET required_attributes = ARRAY(
          SELECT required.attribute
          FROM unnest(base.required_attributes) WITH ORDINALITY AS required(attribute, position)
          WHERE NOT required.attribute = ANY(v.form_configuration_excluded_elements)
          ORDER BY required.position
        )
        FROM type_variants base
        WHERE base.type_id = v.type_id
          AND base.is_default_variant
          AND #{linked('v')}
      SQL
    end

    execute <<~SQL.squish
      UPDATE type_variants
      SET form_configuration_excluded_elements = '{}'
      WHERE NOT #{linked('type_variants')}
    SQL
  end

  def rekey_custom_fields_types
    add_column :custom_fields_types, :form_configuration_id, :bigint

    say_with_time "Move active custom fields from variants to their forms" do
      execute <<~SQL.squish
        DELETE FROM custom_fields_types cft
        USING type_variants v
        WHERE v.id = cft.type_variant_id
          AND #{linked('v')}
      SQL

      execute <<~SQL.squish
        UPDATE custom_fields_types cft
        SET form_configuration_id = v.form_configuration_id
        FROM type_variants v
        WHERE v.id = cft.type_variant_id
      SQL
    end

    remove_index_on :custom_fields_types, "custom_fields_types_unique", %w[custom_field_id type_variant_id]
    remove_foreign_key :custom_fields_types, column: :type_variant_id
    remove_index :custom_fields_types, :type_variant_id
    remove_column :custom_fields_types, :type_variant_id

    change_column_null :custom_fields_types, :form_configuration_id, false
    add_index :custom_fields_types, :form_configuration_id
    add_index :custom_fields_types, %i[custom_field_id form_configuration_id],
              unique: true,
              name: "custom_fields_types_unique"
    add_foreign_key :custom_fields_types, :form_configurations, column: :form_configuration_id, on_delete: :cascade
  end

  def remove_form_columns_from_type_variants
    remove_foreign_key :type_variants, column: :form_configuration_source_id
    remove_index :type_variants, :form_configuration_source_id
    remove_column :type_variants, :form_configuration_source_id
    remove_column :type_variants, :attribute_groups
  end

  def restore_form_columns_on_type_variants
    add_column :type_variants, :attribute_groups, :text
    add_reference :type_variants, :form_configuration_source,
                  foreign_key: { to_table: :type_variants, on_delete: :restrict },
                  index: true

    execute <<~SQL.squish
      UPDATE type_variants v
      SET linked_aspects = array_append(v.linked_aspects, 'form_configuration'),
          form_configuration_source_id = base.id
      FROM type_variants base
      WHERE base.type_id = v.type_id
        AND base.is_default_variant
        AND NOT v.is_default_variant
        AND base.form_configuration_id = v.form_configuration_id
    SQL

    execute <<~SQL.squish
      UPDATE type_variants v
      SET attribute_groups = f.attribute_groups
      FROM form_configurations f
      WHERE f.id = v.form_configuration_id
        AND NOT #{linked('v')}
    SQL
  end

  def restore_custom_fields_types
    add_column :custom_fields_types, :type_variant_id, :bigint
    remove_index_on :custom_fields_types, "custom_fields_types_unique", %w[custom_field_id form_configuration_id]

    execute <<~SQL.squish
      INSERT INTO custom_fields_types (custom_field_id, form_configuration_id, type_variant_id)
      SELECT cft.custom_field_id, cft.form_configuration_id, v.id
      FROM custom_fields_types cft
      INNER JOIN type_variants v ON v.form_configuration_id = cft.form_configuration_id
      WHERE NOT #{linked('v')}
    SQL

    execute "DELETE FROM custom_fields_types WHERE type_variant_id IS NULL"

    remove_foreign_key :custom_fields_types, column: :form_configuration_id
    remove_index :custom_fields_types, :form_configuration_id
    remove_column :custom_fields_types, :form_configuration_id

    change_column_null :custom_fields_types, :type_variant_id, false
    add_index :custom_fields_types, :type_variant_id
    add_index :custom_fields_types, %i[custom_field_id type_variant_id],
              unique: true,
              name: "custom_fields_types_unique"
    add_foreign_key :custom_fields_types, :type_variants, column: :type_variant_id, on_delete: :cascade
  end
end
