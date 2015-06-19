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

class RemoveJournalColumns < ActiveRecord::Migration
  def up
    change_table :work_package_journals do |t|
      t.remove :lock_version, :created_at, :root_id, :lft, :rgt
    end

    change_table :wiki_content_journals do |t|
      t.remove :lock_version
    end

    change_table :time_entry_journals do |t|
      t.remove :created_on
    end

    change_table :news_journals do |t|
      t.remove :created_on
    end

    change_table :message_journals do |t|
      t.remove :created_on
    end

    change_table :journals do |t|
      t.remove_references :journable_data, polymorphic: true
    end

    change_table :attachment_journals do |t|
      t.remove :created_on
    end

    change_table :customizable_journals do |t|
      t.remove :default_value
    end

    drop_table :journal_details
  end

  def down
    change_table :work_package_journals do |t|
      t.integer :lock_version,                    default: 0,  null: false
      t.datetime :created_at
      t.integer :root_id
      t.integer :lft
      t.integer :rgt
    end

    change_table :wiki_content_journals do |t|
      t.integer :lock_version,                     default: 0,  null: false
    end

    change_table :time_entry_journals do |t|
      t.datetime :created_on
    end

    change_table :news_journals do |t|
      t.datetime :created_on
    end

    change_table :message_journals do |t|
      t.datetime :created_on
    end

    change_table :journals do |t|
      t.references :journable_data, polymorphic: true
    end

    change_table :attachment_journals do |t|
      t.datetime :created_on
    end

    change_table :customizable_journals do |t|
      t.string :default_value
    end

    create_table :journal_details do |t|
      t.integer :journal_id,               default: 0,  null: false
      t.string :property,   limit: 30, default: '', null: false
      t.string :prop_key,   limit: 30, default: '', null: false
      t.text :old_value
      t.text :value
    end
  end
end
