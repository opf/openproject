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

class AddBcfPlugin < ActiveRecord::Migration[5.1]
  def change
    create_table :bcf_issues do |t|
      t.text :uuid, index: true
      t.column :markup, :xml

      t.references :project, foreign_key: { on_delete: :cascade }, index: true
      t.references :work_package, foreign_key: { on_delete: :cascade }, index: { unique: true }
    end

    create_table :bcf_viewpoints do |t|
      t.text :uuid, index: true
      t.column :viewpoint, :xml
      t.text :viewpoint_name

      t.references :issue,
                   foreign_key: { to_table: :bcf_issues, on_delete: :cascade }

      # Create unique index on issue and uuid to avoid duplicates on resynchronization
      t.index %i[uuid issue_id], unique: true
    end

    create_table :bcf_comments do |t|
      t.text :uuid, index: true
      t.references :journal, index: true

      t.references :issue,
                   foreign_key: { to_table: :bcf_issues, on_delete: :cascade },
                   index: true

      # Create unique index on issue and uuid to avoid duplicates on resynchronization
      t.index %i[uuid issue_id], unique: true
    end
  end
end
