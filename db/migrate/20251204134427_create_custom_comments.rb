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

class CreateCustomComments < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_comments do |t|
      t.references :custom_field, foreign_key: true, null: false
      t.references :customized, polymorphic: true, null: false
      t.text :text, null: false

      t.timestamps

      t.index %i[custom_field_id customized_type customized_id], unique: true
    end

    create_table :custom_comment_journals do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :custom_field, null: false
      t.references :journal, foreign_key: true, null: false
      t.text :text, null: false
    end

    add_column :custom_fields, :has_comment, :boolean, default: false, null: false
  end
end
