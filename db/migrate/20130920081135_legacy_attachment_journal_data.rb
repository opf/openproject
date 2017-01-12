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

class LegacyAttachmentJournalData < ActiveRecord::Migration[4.2]
  def up
    add_index 'attachment_journals', ['journal_id']

    migrator.run
  end

  def down
    migrator.remove_journals_derived_from_legacy_journals

    remove_index 'attachment_journals', ['journal_id']
  end

  private

  def migrator
    @migrator ||= Migration::LegacyJournalMigrator.new('AttachmentJournal', 'attachment_journals') do
      def migrate_key_value_pairs!(to_insert, _legacy_journal, _journal_id)
        rewrite_issue_container_to_work_package(to_insert)
      end

      def rewrite_issue_container_to_work_package(to_insert)
        if to_insert['container_type'].last == 'Issue'

          to_insert['container_type'][-1] = 'WorkPackage'

        end
      end
    end
  end
end
