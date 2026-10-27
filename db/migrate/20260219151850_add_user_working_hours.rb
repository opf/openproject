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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class AddUserWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :user_working_hours do |t|
      t.references :user, null: false, foreign_key: true

      t.date :valid_from, null: false, index: true
      t.integer :monday, null: false
      t.integer :tuesday, null: false
      t.integer :wednesday, null: false
      t.integer :thursday, null: false
      t.integer :friday, null: false
      t.integer :saturday, null: false
      t.integer :sunday, null: false
      t.integer :availability_factor, null: false, default: 100

      t.timestamps
    end
  end
end
