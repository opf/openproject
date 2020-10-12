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

class RemoveWikiContentVersions < ActiveRecord::Migration[5.1]
  def up
    drop_table :wiki_content_versions
  end

  def down
    create_table :wiki_content_versions, force: true do |t|
      t.integer :wiki_content_id, null: false
      t.integer :page_id, null: false
      t.integer :author_id
      t.binary :data, limit: 16.megabytes
      t.string :compression, limit: 6, default: ''
      t.string :comments, default: ''
      t.datetime :updated_on, null: false
      t.integer :version, null: false
    end

    add_index :wiki_content_versions, [:updated_on], name: 'index_wiki_content_versions_on_updated_on'
    add_index :wiki_content_versions, [:wiki_content_id], name: 'wiki_content_versions_wcid'
  end
end
