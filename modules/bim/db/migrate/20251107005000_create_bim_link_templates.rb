# frozen_string_literal: true

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

class CreateBimLinkTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_link_templates do |t|
      t.string :name, null: false
      t.text :description
      t.integer :relationship_type, null: false, default: 0
      t.string :work_package_type
      t.jsonb :element_filters, default: {}
      t.jsonb :template_data, default: {}
      t.boolean :auto_apply, default: false
      t.boolean :public, default: false
      t.references :project, foreign_key: true, null: true
      t.references :author, foreign_key: { to_table: :users }, null: false

      t.timestamps

      t.index :name
      t.index :relationship_type
      t.index :public
      t.index [:project_id, :name], unique: true, where: 'project_id IS NOT NULL'
      t.index :element_filters, using: :gin
      t.index :template_data, using: :gin
    end
  end
end
