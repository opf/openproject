#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class RemoveTimelinesAndReportings < ActiveRecord::Migration[5.0]
  def up
    drop_table :timelines
    drop_table :reportings
    drop_table :available_project_statuses

    delete_reported_project_statuses

    remove_column :project_types, :allows_association
  end

  def down
    create_reportings
    create_timelines
    create_available_project_statuses

    add_column :project_types, :allows_association, :boolean, default: true, null: false
  end

  private

  def create_reportings
    create_table(:reportings, id: :integer) do |t|
      t.column :reported_project_status_comment, :text

      t.belongs_to :project
      t.belongs_to :reporting_to_project
      t.belongs_to :reported_project_status

      t.timestamps
    end
  end

  def create_timelines
    create_table :timelines, id: :integer do |t|
      t.column :name, :string, null: false
      t.column :options, :text

      t.belongs_to :project

      t.timestamps
    end
  end

  def create_available_project_statuses
    create_table(:available_project_statuses, id: :integer) do |t|
      t.belongs_to :project_type
      t.belongs_to :reported_project_status, index: { name: 'index_avail_project_statuses_on_rep_project_status_id' }

      t.timestamps
    end
  end

  def delete_reported_project_statuses
    delete <<-SQL
      DELETE FROM enumerations
      WHERE type = 'ReportedProjectStatus'
    SQL
  end
end
