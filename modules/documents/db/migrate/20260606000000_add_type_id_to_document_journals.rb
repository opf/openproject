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

class AddTypeIdToDocumentJournals < ActiveRecord::Migration[8.0]
  def change
    add_reference :document_journals, :type, foreign_key: { to_table: :document_types }, null: true

    # Backfill type_id from the corresponding document's current type
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE document_journals
          SET type_id = documents.type_id
          FROM journals
          JOIN documents ON documents.id = journals.journable_id
          WHERE journals.data_type = 'Journal::DocumentJournal'
            AND journals.data_id = document_journals.id
        SQL
      end
    end
  end
end
