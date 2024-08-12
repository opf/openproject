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

require_relative "base"

class Tables::Projects < Tables::Base
  # rubocop:disable Metrics/AbcSize
  def self.table(migration)
    create_table migration do |t|
      t.string :name, default: "", null: false
      t.text :description
      t.boolean :is_public, default: true, null: false
      t.integer :parent_id
      t.datetime :created_on
      t.datetime :updated_on
      t.string :identifier
      t.integer :status, default: 1, null: false
      t.integer :lft
      t.integer :rgt
      t.belongs_to :project_type, type: :int
      t.belongs_to :responsible, type: :int
      t.belongs_to :work_packages_responsible, type: :int

      t.index :lft, name: "index_projects_on_lft"
      t.index :rgt, name: "index_projects_on_rgt"
      t.index :identifier
    end
  end
  # rubocop:enable Metrics/AbcSize
end
