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

class CreateLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :labels do |t|
      t.string :name, null: false
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.datetime :archived_at
      t.timestamps
    end
    add_index :labels, "LOWER(name)", unique: true, name: "index_labels_on_LOWER_name"

    create_table :labelings do |t|
      t.references :label, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :labelable, polymorphic: true, null: false, index: false
      t.timestamps
    end
    add_index :labelings, %i[labelable_type labelable_id label_id],
              unique: true,
              name: "index_labelings_on_labelable_and_label"
    add_index :labelings, :label_id
  end
end
