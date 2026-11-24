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

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::JobStatuses < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.references :reference,
                   polymorphic: true,
                   index: { unique: true, name: "index_job_statuses_on_reference_type_and_reference_id" }
      t.string :message
      t.timestamps precision: nil, default: -> { "CURRENT_TIMESTAMP" }
      t.string :status, default: "in_queue"
      t.references :user, index: true
      t.string :job_id, index: { unique: true }
      t.jsonb :payload

      t.check_constraint("status IS NULL OR status IN ('in_queue', 'error', 'in_process', 'success', 'failure', 'cancelled')",
                         name: "delayed_job_statuses_status_check")
    end
  end
end
