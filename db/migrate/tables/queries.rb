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

require_relative 'base'

class Tables::Queries < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.integer :project_id
      t.string :name, default: '', null: false
      t.text :filters
      t.integer :user_id, default: 0, null: false
      t.boolean :is_public, default: false, null: false
      t.text :column_names
      t.text :sort_criteria
      t.string :group_by
      t.boolean :display_sums, default: false, null: false
      t.boolean :timeline_visible, default: false
      t.boolean :show_hierarchies, default: false
      t.integer :timeline_zoom_level, default: 0

      t.index :project_id, name: 'index_queries_on_project_id'
      t.index :user_id, name: 'index_queries_on_user_id'
    end
  end
end
