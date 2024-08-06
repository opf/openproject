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

class TimestampForCaching < ActiveRecord::Migration[5.1]
  class MigratingAuthSource < ApplicationRecord
    self.table_name = "auth_sources"
  end

  def change
    [Enumeration, Status, Category, MigratingAuthSource].each do |model|
      add_timestamps(model)
    end
  end

  def add_timestamps(model)
    table = model.table_name

    change_table table do |t|
      t.timestamps null: true
    end

    model.update_all(updated_at: Time.now, created_at: Time.now)

    change_column_null table, :created_at, false
    change_column_null table, :updated_at, false
  end
end
