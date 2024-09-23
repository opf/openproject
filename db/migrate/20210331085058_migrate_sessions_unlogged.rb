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

class MigrateSessionsUnlogged < ActiveRecord::Migration[6.1]
  def up
    truncate :sessions

    # Set the table to UNLOGGED
    execute <<~SQL.squish
      ALTER TABLE "sessions" SET UNLOGGED
    SQL

    # We don't need the created at column
    # that now no longer is set by rails
    remove_column :sessions, :created_at, null: false
  end

  def down
    # Set the table to LOGGED
    execute <<~SQL.squish
      ALTER TABLE "sessions" SET LOGGED
    SQL

    add_column :sessions, :created_at, :datetime
  end
end
