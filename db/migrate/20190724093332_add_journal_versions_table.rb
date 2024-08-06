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

require_relative "migration_utils/utils"

class AddJournalVersionsTable < ActiveRecord::Migration[5.2]
  include ::Migration::Utils

  def up
    create_table :journal_versions do |t|
      t.string :journable_type
      t.integer :journable_id
      t.integer :version, default: 0
      t.index %i[journable_type journable_id version],
              name: "unique_journal_version",
              unique: true
    end

    ActiveRecord::Base.connection.execute <<-SQL.squish
          INSERT INTO journal_versions (journable_type, journable_id, version)
          (SELECT
            journable_type, journable_id, MAX(version)
          FROM journals
          GROUP BY journable_type, journable_id);
    SQL
  end

  def down
    drop_table :journal_versions
  end
end
