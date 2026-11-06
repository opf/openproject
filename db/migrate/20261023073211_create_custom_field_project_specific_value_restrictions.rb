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

class CreateCustomFieldProjectSpecificValueRestrictions < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_fields, :project_specific_value_restriction, :string

    create_table :custom_field_project_specific_value_restrictions do |t|
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :custom_field, null: false,
                                  index: { name: "index_cf_ps_value_restrictions_on_custom_field" },
                                  foreign_key: { on_delete: :cascade }
      t.string :restriction, null: false
      t.references :custom_option, index: { name: "index_cf_ps_value_restrictions_on_option" },
                                   foreign_key: { on_delete: :cascade }
      t.references :hierarchy_item, index: { name: "index_cf_ps_value_restrictions_on_item" },
                                    foreign_key: { to_table: :hierarchical_items, on_delete: :cascade }
      t.timestamps

      t.index %i[project_id custom_option_id], unique: true, name: "index_cf_ps_value_restrictions_on_project_and_option"
      t.index %i[project_id hierarchy_item_id], unique: true, name: "index_cf_ps_value_restrictions_on_project_and_item"
      t.check_constraint "num_nonnulls(custom_option_id, hierarchy_item_id) = 1",
                         name: "cf_ps_value_restrictions_one_value"
    end
  end
end
