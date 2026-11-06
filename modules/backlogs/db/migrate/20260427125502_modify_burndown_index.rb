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

class ModifyBurndownIndex < ActiveRecord::Migration[8.1]
  INDEX_NAME = "work_package_journal_on_burndown_attributes"

  def up
    remove_and_add_burndown_index :sprint_id
  end

  def down
    remove_and_add_burndown_index :version_id
  end

  private

  def remove_and_add_burndown_index(column)
    remove_index(:work_package_journals, name: INDEX_NAME) if index_exists?(:work_package_journals, name: INDEX_NAME)

    add_index :work_package_journals,
              [column,
               :status_id,
               :project_id,
               :type_id],
              name: INDEX_NAME
  end
end
