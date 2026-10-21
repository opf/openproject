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

class CreateLabelJournals < ActiveRecord::Migration[8.1]
  def change
    create_table :label_journals do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.belongs_to :journal, null: false, foreign_key: true
      # No foreign key: journal snapshots must outlive deleted labels.
      t.belongs_to :label, null: false
    end

    # Existing journals predate this table, so only the latest journal of each
    # labelled work package gets a snapshot of its current labels. That keeps
    # the next save from journaling a spurious change; older journals cannot be
    # reconstructed and stay empty.
    reversible do |dir|
      dir.up do
        say_with_time "Snapshotting current work package labels onto each latest journal" do
          execute(<<~SQL.squish)
            INSERT INTO label_journals (journal_id, label_id)
            SELECT latest.id, labelings.label_id
            FROM labelings
            INNER JOIN LATERAL (
              SELECT journals.id
              FROM journals
              WHERE journals.journable_type = 'WorkPackage'
                AND journals.journable_id = labelings.labelable_id
              ORDER BY journals.version DESC
              LIMIT 1
            ) latest ON TRUE
            WHERE labelings.labelable_type = 'WorkPackage'
          SQL
        end
      end
    end
  end
end
