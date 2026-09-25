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

# Position uniqueness is deferred: acts_as_list shifts neighbours with bulk updates that would
# collide with an immediately checked index.
class CreateFormConfigurationTables < ActiveRecord::Migration[8.1]
  # rubocop:disable-next Metrics/AbcSize
  def change
    create_table :form_configuration_groups do |t|
      t.references :type_variant, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
      t.string :kind, null: false
      t.string :default_key
      t.string :label
      t.references :query, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.timestamps

      t.index %i[id type_variant_id], unique: true, name: "index_form_configuration_groups_on_id_and_owner"
      t.index %i[type_variant_id default_key], unique: true, where: "default_key IS NOT NULL",
                                               name: "index_form_configuration_groups_on_owner_and_default_key"
      t.check_constraint "kind IN ('attribute', 'query')", name: "form_configuration_groups_kind"
      t.check_constraint "(kind = 'query') = (query_id IS NOT NULL)",
                         name: "form_configuration_groups_query_matches_kind"
      t.check_constraint "default_key IS NOT NULL OR label IS NOT NULL", name: "form_configuration_groups_named"
      t.unique_constraint %i[type_variant_id position], deferrable: :deferred,
                                                        name: "form_configuration_groups_position"
    end

    create_table :form_configuration_attributes do |t|
      t.references :type_variant, null: false, foreign_key: { on_delete: :cascade }
      t.references :form_configuration_group
      t.integer :position
      t.references :custom_field, foreign_key: { on_delete: :cascade }
      t.string :attribute_key
      t.timestamps

      t.index %i[type_variant_id custom_field_id], unique: true, where: "custom_field_id IS NOT NULL",
                                                   name: "index_form_configuration_attributes_on_owner_and_custom_field"
      t.index %i[type_variant_id attribute_key], unique: true, where: "attribute_key IS NOT NULL",
                                                 name: "index_form_configuration_attributes_on_owner_and_key"
      t.check_constraint "(custom_field_id IS NULL) <> (attribute_key IS NULL)",
                         name: "form_configuration_attributes_one_reference"
      t.check_constraint "(form_configuration_group_id IS NULL) = (position IS NULL)",
                         name: "form_configuration_attributes_placement"
      t.unique_constraint %i[form_configuration_group_id position], deferrable: :deferred,
                                                                    name: "form_configuration_attributes_position"
    end

    add_foreign_key :form_configuration_attributes, :form_configuration_groups,
                    column: %i[form_configuration_group_id type_variant_id],
                    primary_key: %i[id type_variant_id],
                    name: "fk_form_configuration_attributes_group_owner"
  end
end
