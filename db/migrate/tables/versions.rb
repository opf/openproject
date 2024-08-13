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

class Tables::Versions < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.integer :project_id, default: 0, null: false
      t.string :name, default: "", null: false
      t.string :description, default: ""
      t.date :effective_date
      t.datetime :created_on
      t.datetime :updated_on
      t.string :wiki_page_title
      t.string :status, default: :open
      t.string :sharing, default: :none, null: false
      t.date :start_date

      t.index :project_id, name: "versions_project_id"
      t.index :sharing, name: "index_versions_on_sharing"
    end
  end
end
