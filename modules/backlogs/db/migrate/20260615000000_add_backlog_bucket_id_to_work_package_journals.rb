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

class AddBacklogBucketIdToWorkPackageJournals < ActiveRecord::Migration[8.1]
  def change
    add_reference :work_package_journals, :backlog_bucket, foreign_key: { on_delete: :nullify }

    # Buckets predate this column, so historical journals have no record of
    # when a work package's bucket was actually set. We cannot reconstruct
    # that history, so we pragmatically backfill every journal of a work
    # package that currently has a bucket with that same, current bucket.
    # This makes it look as if the bucket had been set since the work
    # package's creation, but means no spurious "bucket set" change will show
    # up until the bucket is actually changed going forward. A work
    # package's sprint and bucket are mutually exclusive, so journals
    # recorded while the work package still had a sprint are skipped: their
    # sprint_id being set proves they predate the bucket, and backfilling
    # them would misrepresent that history. On rollback the column goes
    # away, so nothing to undo here.
    reversible do |dir|
      dir.up do
        say_with_time "Backfilling work_package_journals.backlog_bucket_id from the work package's current bucket" do
          execute(<<~SQL.squish)
            UPDATE work_package_journals
            SET backlog_bucket_id = work_packages.backlog_bucket_id
            FROM journals
            INNER JOIN work_packages
              ON work_packages.id = journals.journable_id
             AND journals.journable_type = 'WorkPackage'
            WHERE journals.data_id = work_package_journals.id
              AND journals.data_type = 'Journal::WorkPackageJournal'
              AND work_packages.backlog_bucket_id IS NOT NULL
              AND work_package_journals.sprint_id IS NULL
          SQL
        end
      end
    end
  end
end
