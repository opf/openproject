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

require_relative 'migration_utils/utils'
require_relative 'migration_utils/legacy_journal_migrator'
require_relative 'migration_utils/journal_migrator_concerns'

class LegacyIssueJournalData < ActiveRecord::Migration[4.2]
  include Migration::Utils

  def up
    add_index 'work_package_journals', ['journal_id']

    migrator.run

    reset_public_key_sequence_in_postgres 'journals'
  end

  def down
    migrator.remove_journals_derived_from_legacy_journals 'customizable_journals',
                                                          'attachable_journals'

    remove_index 'work_package_journals', ['journal_id']
  end

  def migrator
    @migrator ||= Migration::LegacyJournalMigrator.new 'IssueJournal', 'work_package_journals' do
      extend Migration::JournalMigratorConcerns::Attachable
      extend Migration::JournalMigratorConcerns::Customizable

      self.journable_class = 'WorkPackage'

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)
        migrate_attachments(to_insert, legacy_journal, journal_id)

        migrate_custom_values(to_insert, legacy_journal, journal_id)
      end
    end
  end
end
