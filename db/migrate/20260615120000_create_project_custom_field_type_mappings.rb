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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateProjectCustomFieldTypeMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :project_custom_field_type_mappings do |t|
      t.references :type, null: false, foreign_key: true, index: false
      t.references :custom_field, null: false, foreign_key: true,
                                  index: { name: "index_project_cf_type_mappings_on_custom_field_id" }

      t.timestamps

      t.index %i[type_id custom_field_id],
              unique: true,
              name: "index_project_custom_field_type_mappings_unique"
    end
  end
end
