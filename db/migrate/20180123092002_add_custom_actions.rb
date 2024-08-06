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

class AddCustomActions < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_actions, id: :integer do |t|
      t.string :name
      t.text :actions
    end

    create_table :custom_actions_statuses, id: :integer do |t|
      t.belongs_to :status
      t.belongs_to :custom_action
    end

    create_table :custom_actions_roles, id: :integer do |t|
      t.belongs_to :role
      t.belongs_to :custom_action
    end

    create_table :custom_actions_types, id: :integer do |t|
      t.belongs_to :type
      t.belongs_to :custom_action
    end

    create_table :custom_actions_projects, id: :integer do |t|
      t.belongs_to :project
      t.belongs_to :custom_action
    end
  end
end
