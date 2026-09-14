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

# Two partial indexes rather than one over (type_id, name, project_id): NULLs compare as distinct
# in a unique index, so the global rows would not be constrained at all.
class ScopeVariantNamesToOwningProject < ActiveRecord::Migration[8.0]
  include Migration::Utils

  GLOBAL_INDEX = "index_type_variants_on_type_id_and_LOWER_variant_name"
  OWNED_INDEX = "index_type_variants_on_type_id_project_and_LOWER_variant_name"

  def up
    remove_index_on :type_variants, GLOBAL_INDEX

    add_index :type_variants, "type_id, lower(variant_name)",
              unique: true,
              where: "variant_name IS NOT NULL AND project_id IS NULL",
              name: GLOBAL_INDEX
    add_index :type_variants, "type_id, project_id, lower(variant_name)",
              unique: true,
              where: "variant_name IS NOT NULL AND project_id IS NOT NULL",
              name: OWNED_INDEX
  end

  def down
    remove_index_on :type_variants, OWNED_INDEX
    remove_index_on :type_variants, GLOBAL_INDEX

    add_index :type_variants, "type_id, lower(variant_name)",
              unique: true,
              where: "variant_name IS NOT NULL",
              name: GLOBAL_INDEX
  end
end
