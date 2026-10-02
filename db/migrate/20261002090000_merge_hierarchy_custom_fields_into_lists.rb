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

class MergeHierarchyCustomFieldsIntoLists < ActiveRecord::Migration[8.1]
  def up
    add_column :custom_fields, :was_list, :boolean,
               default: false,
               null: false,
               comment: "Former option list, whose items may still be referenced by legacy custom option ids."

    execute "UPDATE custom_fields SET was_list = true WHERE field_format = 'list'"
    execute "UPDATE custom_fields SET field_format = 'list' WHERE field_format = 'hierarchy'"
  end

  # Lists created since the migration come back as hierarchies.
  def down
    execute "UPDATE custom_fields SET field_format = 'hierarchy' WHERE field_format = 'list' AND NOT was_list"

    remove_column :custom_fields, :was_list
  end
end
