#-- encoding: UTF-8
#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++
#

require Rails.root.join('db', 'migrate', 'migration_utils', 'legacy_journal_migrator').to_s

class LegacyMeetingAgendaJournalData < ActiveRecord::Migration[5.0]
  class UnsupportedMeetingAgendaJournalCompressionError < ::StandardError
  end

  def up
    migrator.run
  end

  def down
    migrator.remove_journals_derived_from_legacy_journals 'meeting_content_journals'
  end

  def migrator
    @migrator ||= Migration::LegacyJournalMigrator.new 'MeetingAgendaJournal', 'meeting_content_journals' do

      self.journable_class = 'MeetingContent'

      def migrate_key_value_pairs!(to_insert, _legacy_journal, _journal_id)
        if to_insert.has_key?('data')

          # Why is that checked but than the compression is not used in any way to read the data
          if !to_insert.has_key?('compression')

            raise UnsupportedMeetingAgendaJournalCompressionError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
              There is a MeetingAgenda journal that contains data in an
              unsupported compression: #{compression}
            MESSAGE

          end

          # as the old journals used the format [old_value, new_value] we have to fake it here
          to_insert['text'] = [nil, to_insert.delete('data')]
        end
      end

    end
  end
end
