#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class RemoveAlternateDatesAndScenarios < ActiveRecord::Migration[4.2]
  def up
    drop_table(:alternate_dates)
    drop_table(:scenarios)
  end

  def down
    create_table(:scenarios) do |t|
      t.column :name,        :string, null: false
      t.column :description, :text

      t.belongs_to :project

      t.timestamps
    end

    add_index :scenarios, :project_id

    create_table(:alternate_dates) do |t|
      t.column :start_date, :date, null: false
      t.column :due_date,   :date, null: false

      t.belongs_to :scenario
      t.belongs_to :planning_element

      t.timestamps
    end

    add_index :alternate_dates, :planning_element_id
    add_index :alternate_dates, :scenario_id

    add_index :alternate_dates,
              [:updated_at, :planning_element_id, :scenario_id],
              unique: true,
              name: 'index_ad_on_updated_at_and_planning_element_id'
  end
end
