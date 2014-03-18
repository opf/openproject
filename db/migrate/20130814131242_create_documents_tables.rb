#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
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

class CreateDocumentsTables < ActiveRecord::Migration
  def up
    unless ActiveRecord::Base.connection.table_exists? 'documents'
      create_table "documents" do |t|
        t.integer  "project_id",                :default => 0,  :null => false
        t.integer  "category_id",               :default => 0,  :null => false
        t.string   "title",       :limit => 60, :default => "", :null => false
        t.text     "description"
        t.datetime "created_on"
      end
      add_index "documents", ["category_id"], :name => "index_documents_on_category_id"
      add_index "documents", ["created_on"], :name => "index_documents_on_created_on"
      add_index "documents", ["project_id"], :name => "documents_project_id"
    end
  end

  def down
    drop_table :documents
  end
end
