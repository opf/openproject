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

class NullifyGroupDetailsParentOnDelete < ActiveRecord::Migration[8.1]
  # Deleting a department that is the parent of another one used to fail because the
  # group_details.parent_id foreign key restricted it. Nullify children's parent instead, so the
  # children become top-level departments.
  def up
    remove_foreign_key :group_details, column: :parent_id
    add_foreign_key :group_details, :users, column: :parent_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :group_details, column: :parent_id
    add_foreign_key :group_details, :users, column: :parent_id
  end
end
