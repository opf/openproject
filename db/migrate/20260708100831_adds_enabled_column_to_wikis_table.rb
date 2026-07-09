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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class AddsEnabledColumnToWikisTable < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    say "Creating enabled column on wikis"
    add_column :wikis, :enabled, :boolean, default: true, null: false

    transaction do
      say "Updating wiki enabled state based on enabled modules"
      execute <<~SQL.squish
        UPDATE wikis
        SET enabled = false
        WHERE project_id NOT IN (select project_id from enabled_modules where name = 'wiki');
      SQL

      say "Removing wiki from the list of enabled modules"
      execute <<~SQL.squish
        DELETE FROM enabled_modules WHERE name = 'wiki';
      SQL
    end
  end

  def down
    execute <<~SQL.squish
      INSERT INTO enabled_modules (project_id, name)
      SELECT project_id, 'wiki' from wikis where enabled = true;
    SQL

    remove_column :wikis, :enabled
  end
end
