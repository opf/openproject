#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class AddPlanningElementTypePropertiesToType < ActiveRecord::Migration
  def up
    add_column :types, :in_aggregation, :boolean, default: true,  null: false
    add_column :types, :is_milestone,   :boolean, default: false, null: false
    add_column :types, :is_default,     :boolean, default: false, null: false

    add_column :types, :color_id,   :integer

    # We have to add the created_at and updated_at columns
    # in two phases as there might already be values in the db.
    # Enforcing not null will break on existing values.
    # Thus, we first create the column, add values for all existing
    # entries and then add the not null constraint.
    add_column :types, :created_at, :datetime
    add_column :types, :updated_at, :datetime

    Type.update_all({ created_at: Time.now, updated_at: Time.now },
                    { created_at: nil, updated_at: nil })

    change_column :types, :created_at, :datetime, null: false
    change_column :types, :updated_at, :datetime, null: false

    change_column :types, :name, :string, default: '', null: false

    add_index :types, [:color_id], name: :index_types_on_color_id
  end

  def down
    remove_column :types, :in_aggregation
    remove_column :types, :is_milestone
    remove_column :types, :is_default

    remove_column :types, :color_id
    remove_column :types, :created_at
    remove_column :types, :updated_at

    change_column :types, :name, :string, limit: 30, default: '', null: false
  end
end
