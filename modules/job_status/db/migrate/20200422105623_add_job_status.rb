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

class AddJobStatus < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE delayed_job_status AS ENUM ('in_queue', 'error', 'in_process', 'success', 'failure');
    SQL

    create_table :delayed_job_statuses do |t|
      t.references :job
      t.references :reference, polymorphic: true, index: { unique: true }
      t.string :message

      t.timestamps
    end

    add_column :delayed_job_statuses, :status, :delayed_job_status, default: "in_queue"
  end

  def down
    drop_table :delayed_job_statuses

    execute <<-SQL.squish
      DROP TYPE delayed_job_status;
    SQL
  end
end
