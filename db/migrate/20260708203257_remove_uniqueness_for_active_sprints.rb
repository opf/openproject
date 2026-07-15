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

class RemoveUniquenessForActiveSprints < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    remove_index :sprints, name: "index_sprints_on_project_id_when_active"
  end

  def down
    duplicates = exec_query(<<~SQL.squish).rows
      SELECT project_id FROM sprints WHERE status = 'active'
      GROUP BY project_id HAVING COUNT(*) > 1
    SQL

    if duplicates.any?
      raise "Cannot roll back: projects #{duplicates.flatten.join(', ')} have multiple active sprints. " \
            "Complete all but one active sprint per project before rolling back this migration."
    end

    add_index :sprints, :project_id, unique: true,
                                     where: "status = 'active'",
                                     algorithm: :concurrently,
                                     name: "index_sprints_on_project_id_when_active"
  end
end
