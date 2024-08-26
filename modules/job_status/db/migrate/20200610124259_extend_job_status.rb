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

class ExtendJobStatus < ActiveRecord::Migration[6.0]
  # ALTER TYPE has to run outside transaction
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          ALTER TYPE delayed_job_status ADD VALUE IF NOT EXISTS 'cancelled';
        SQL
      end
    end

    ActiveRecord::Base.transaction do
      remove_reference :delayed_job_statuses, :job

      change_table :delayed_job_statuses do |t|
        t.references :user, index: true
        t.string :job_id, index: { unique: true }
        t.jsonb :payload
      end

      reversible do |dir|
        dir.up do
          change_column_default :delayed_job_statuses, :created_at, -> { "CURRENT_TIMESTAMP" }
          change_column_default :delayed_job_statuses, :updated_at, -> { "CURRENT_TIMESTAMP" }
        end
      end

      # Now that we have user reference on job status
      # we don't need it on export
      remove_reference :work_package_exports, :user
    end
  end
end
