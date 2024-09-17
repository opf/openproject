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

class EnsurePostgresIndexNames < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    sql = <<~SQL.squish
      SELECT
        FORMAT('%s_pkey', table_name) as new_name,
        constraint_name as old_name
      FROM information_schema.table_constraints
      WHERE UPPER(constraint_type) = 'PRIMARY KEY'
      AND constraint_schema IN (select current_schema())
      AND constraint_name != FORMAT('%s_pkey', table_name)
      ORDER BY table_name;
    SQL

    ActiveRecord::Base.connection.execute(sql).each do |entry|
      old_name = entry["old_name"]
      new_name = entry["new_name"]

      ActiveRecord::Base.transaction do
        execute %(ALTER INDEX "#{old_name}" RENAME TO #{new_name};)
      rescue StandardError => e
        warn "Failed to rename index #{old_name} to #{new_name}: #{e.message}. Skipping"
      end
    end
  end

  def down
    # Nothing to do
  end
end
