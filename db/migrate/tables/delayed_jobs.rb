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

require_relative "base"

class Tables::DelayedJobs < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.integer :priority, default: 0   # Allows some jobs to jump to the front of the queue
      t.integer :attempts, default: 0   # Provides for retries, but still fail eventually.
      t.text :handler                   # YAML-encoded string of the object that will do work
      t.text :last_error                # reason for last failure (See Note below)
      t.datetime :run_at                # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      t.datetime :locked_at             # Set when a client is working on this object
      t.datetime :failed_at             # Set when all retries have failed (actually, by default, the record is deleted instead)
      t.string :locked_by               # Who is working on this object (if locked)
      t.timestamps null: true
      t.string :queue

      t.index %i[priority run_at], name: "delayed_jobs_priority"
    end
  end
end
