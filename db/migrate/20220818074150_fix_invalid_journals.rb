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

class FixInvalidJournals < ActiveRecord::Migration[7.0]
  def up
    get_broken_journals.each do |journable_type, relation|
      next unless relation.any?

      # rubocop:disable Rails/Output
      puts "Cleaning up broken journals on #{journable_type}"
      # rubocop:enable Rails/Output
      destroy_journals(relation)
    end
  end

  def down
    # nothing to do
  end

  def destroy_journals(journals)
    journal_ids = journals.pluck(:id)

    Journal::AttachableJournal.where(journal_id: journal_ids).delete_all
    Journal::CustomizableJournal.where(journal_id: journal_ids).delete_all

    journals.delete_all

    # We delete manually the related journals here rather than
    # relying on .destroy. This is because in the future (from
    # the migration's perspective) new such journals may appear
    # which do not yet exist at the point of this migration.
    #
    # This is to avoid errors such as the following:
    #   PG::UndefinedTable: ERROR:  relation "storages_file_links_journals" does not exist
    #     LINE 9:  WHERE a.attrelid = '"storages_file_links_journals"'::regcla...
  end

  def get_broken_journals
    Journal
      .pluck("DISTINCT(journable_type)")
      .compact
      .to_h do |journable_type|
      relation = Journal
        .where(journable_type:)
        .where.not(data_type: "Journal::#{journable_type}Journal")

      [journable_type, relation]
    end
  end
end
