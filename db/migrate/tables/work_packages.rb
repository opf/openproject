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

class Tables::WorkPackages < Tables::Base
  # rubocop:disable Metrics/AbcSize
  def self.table(migration)
    create_table migration do |t|
      t.integer :type_id, default: 0, null: false
      t.belongs_to :project, default: 0, null: false, type: :int
      t.string :subject, default: "", null: false
      t.text :description
      t.date :due_date
      t.integer :category_id
      t.integer :status_id, default: 0, null: false
      t.integer :assigned_to_id
      t.integer :priority_id, null: true, default: 0
      t.integer :fixed_version_id
      t.integer :author_id, default: 0, null: false
      t.integer :lock_version, default: 0, null: false
      t.integer :done_ratio, default: 0, null: false
      t.float :estimated_hours
      t.timestamps null: true
      t.date :start_date
      t.belongs_to :parent, default: nil, type: :int
      t.belongs_to :responsible, type: :int

      # Nested Set
      t.integer :root_id, default: nil
      t.integer :lft, default: nil
      t.integer :rgt, default: nil

      # Nested Set
      t.index %i[root_id lft rgt]

      t.index :type_id
      t.index :status_id
      t.index :category_id
      t.index :author_id
      t.index :assigned_to_id
      t.index :created_at
      t.index :fixed_version_id
      t.index :updated_at
      t.index %i[project_id updated_at]
    end
  end
  # rubocop:enable Metrics/AbcSize
end
