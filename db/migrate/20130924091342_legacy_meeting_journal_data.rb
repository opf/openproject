#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
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

require_relative 'migration_utils/legacy_journal_migrator'

class LegacyMeetingJournalData < ActiveRecord::Migration
  def up
    migrator.run
  end

  def down
    migrator.remove_journals_derived_from_legacy_journals 'meeting_journals'
  end

  def migrator
    @migrator ||= Migration::LegacyJournalMigrator.new "MeetingJournal", "meeting_journals"
  end
end
