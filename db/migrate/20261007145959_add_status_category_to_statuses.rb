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

class AddStatusCategoryToStatuses < ActiveRecord::Migration[8.1]
  def up
    add_column :statuses, :category, :string

    execute <<~SQL.squish
      UPDATE statuses SET category = 'closed'
      WHERE statuses.is_closed = true;
    SQL

    remove_column :statuses, :is_closed
    add_index :statuses, :category, name: "index_statuses_on_category"
  end

  def down
    add_column :statuses, :is_closed, :boolean, default: false, null: false

    execute <<~SQL.squish
      UPDATE statuses SET is_closed = true
      WHERE statuses.category = 'closed';
    SQL

    remove_column :statuses, :category
    add_index :statuses, :is_closed, name: "index_statuses_on_is_closed"
  end
end
