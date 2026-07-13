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

class CreateWorkPackageVersionJournals < ActiveRecord::Migration[8.1]
  def change
    create_table :work_package_version_journals do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.belongs_to :journal, null: false, foreign_key: true
      # No foreign key: journal snapshots must outlive deleted versions,
      # like the other *_journals side tables.
      t.belongs_to :version, null: false
      t.enum :kind, enum_type: :work_package_version_kind, null: false
    end

    # Existing journals predate the snapshot table. Without snapshot rows for
    # the most recent journal, the next save of any work package with a version
    # would journal a spurious "target versions set" change. During the
    # transition the target versions mirror the single version_id, so every
    # historical journal's target set can be reconstructed exactly from its
    # data row. On rollback the rows go away with the table.
    reversible do |dir|
      dir.up do
        say_with_time "Copying work_package_journals.version_id into work_package_version_journals (kind: target)" do
          execute(<<~SQL.squish)
            INSERT INTO work_package_version_journals (journal_id, version_id, kind)
                SELECT journals.id, work_package_journals.version_id, 'target'
                FROM journals
                INNER JOIN work_package_journals ON work_package_journals.id = journals.data_id
                WHERE journals.data_type = 'Journal::WorkPackageJournal'
                  AND work_package_journals.version_id IS NOT NULL
          SQL
        end
      end
    end
  end
end
