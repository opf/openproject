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

class BackfillTargetVersionsFromWorkPackage < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Copying work_packages.version_id into work_package_associated_versions (kind: target)" do
      execute <<~SQL.squish
        INSERT INTO work_package_versions (work_package_id, version_id, kind, created_at, updated_at)
            SELECT work_packages.id, work_packages.version_id, 'target', now(), now()
            FROM work_packages
            INNER JOIN versions ON versions.id = work_packages.version_id
            WHERE work_packages.version_id IS NOT NULL
        ON CONFLICT (work_package_id, version_id, kind) DO NOTHING
      SQL
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
