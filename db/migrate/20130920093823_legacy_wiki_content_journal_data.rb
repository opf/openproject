#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/legacy_journal_migrator'

class LegacyWikiContentJournalData < ActiveRecord::Migration[4.2]
  class UnsupportedWikiContentJournalCompressionError < ::StandardError
  end

  def up
    add_index 'wiki_content_journals', ['journal_id']

    migrator.run
  end

  def down
    migrator.remove_journals_derived_from_legacy_journals

    remove_index 'wiki_content_journals', ['journal_id']
  end

  def migrator
    @migrator ||= Migration::LegacyJournalMigrator.new('WikiContentJournal', 'wiki_content_journals') do
      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)
        # remove once lock_version is no longer a column in the wiki_content_journales table
        if !to_insert.has_key?('lock_version')

          if !legacy_journal.has_key?('version')
            raise WikiContentJournalVersionError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
              There is a wiki content without a version.
              The DB requires a version to be set
              #{legacy_journal},
              #{to_insert}
            MESSAGE

          end

          # as the old journals used the format [old_value, new_value] we have to fake it here
          to_insert['lock_version'] = [nil, legacy_journal['version']]
        end

        if to_insert.has_key?('data')

          # Why is that checked but than the compression is not used in any way to read the data
          if !to_insert.has_key?('compression')

            raise UnsupportedWikiContentJournalCompressionError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
              There is a WikiContent journal that contains data in an
              unsupported compression: #{compression}
            MESSAGE

          end

          # as the old journals used the format [old_value, new_value] we have to fake it here
          to_insert['text'] = [nil, to_insert.delete('data')]

          # fix non null constraint violation on page_id.
          to_insert['page_id'] = [nil, journal_id]

        end
      end
    end
  end
end
