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
# This program is distributed in the hope that itwill be useful,
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

class AddHealthInfoToStorages < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE storage_health_statuses AS ENUM ('pending', 'healthy', 'unhealthy');
    SQL
    add_column(:storages, :health_status, :storage_health_statuses, null: false, default: "pending")
    add_column(:storages, :health_changed_at, :datetime, null: false, default: -> { "current_timestamp" })
    add_column(:storages, :health_reason, :string)
  end

  def down
    remove_column(:storages, :health_status)
    remove_column(:storages, :health_changed_at)
    remove_column(:storages, :health_reason)

    execute <<-SQL.squish
      DROP TYPE storage_health_statuses;
    SQL
  end
end
