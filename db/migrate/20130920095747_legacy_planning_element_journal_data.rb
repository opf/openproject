#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
#

require_relative 'migration_utils/legacy_journal_migrator'
require_relative 'migration_utils/journal_migrator_concerns'

class LegacyPlanningElementJournalData < ActiveRecord::Migration
  include Migration::Utils

  class UnknownJournaledError < ::StandardError
  end

  class UnknownTypeError < ::StandardError
  end

  def up
    migrator.run

    reset_public_key_sequence_in_postgres 'journals'
  end

  def down
    migrator.remove_journals_derived_from_legacy_journals 'customizable_journals',
                                                          'attachable_journals'
  end

  def migrator
    @migrator ||= Migration::LegacyJournalMigrator.new "Timelines_PlanningElementJournal", "work_package_journals" do
      extend Migration::JournalMigratorConcerns::Attachable
      extend Migration::JournalMigratorConcerns::Customizable

      self.journable_class = "WorkPackage"

      def migrate(legacy_journal)
        update_journaled_id(legacy_journal)

        super
      end

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)

        update_type_id(to_insert)

        set_empty_description(to_insert)

        migrate_attachments(to_insert, legacy_journal, journal_id)

        migrate_custom_values(to_insert, legacy_journal, journal_id)

      end

      def update_journaled_id(legacy_journal)
        new_journaled_id = new_journaled_id_for_old(legacy_journal["journaled_id"])

        if new_journaled_id.nil?
          raise UnknownJournaledError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
          No new journaled_id could be found to replace the journaled_id value of
          #{legacy_journal["journaled_id"]} for the legacy journal with the id
          #{legacy_journal["id"]}
          MESSAGE
        end

        legacy_journal["journaled_id"] = new_journaled_id
      end

      def update_type_id(to_insert)
        return if to_insert["planning_element_type_id"].nil? ||
                  to_insert["planning_element_type_id"].last.nil?

        new_type_id = new_type_id_for_old(to_insert["planning_element_type_id"].last)

        if new_type_id.nil?
          raise UnknownTypeError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
          No new type_id could be found to replace the type_id value of
          #{to_insert["planning_element_type_id"].last}
          MESSAGE
        end

        to_insert["type_id"] = [nil, new_type_id]
      end

      def new_journaled_id_for_old(old_journaled_id)
        @new_journaled_ids ||= begin
          old_new = db_select_all <<-SQL
            SELECT journaled_id AS old_id, new_id
            FROM legacy_journals
            LEFT JOIN legacy_planning_elements
            ON legacy_journals.journaled_id = legacy_planning_elements.id
            WHERE type = 'Timelines_PlanningElementJournal'
          SQL

          old_new.inject({}) do |mem, entry|
            mem[entry['old_id']] = entry['new_id']
            mem
          end
        end

        @new_journaled_ids[old_journaled_id]
      end

      def new_type_id_for_old(old_type_id)
        @new_type_ids ||= begin
          old_new = db_select_all <<-SQL
            SELECT id AS old_id, new_id
            FROM legacy_planning_element_types
          SQL

          old_new.inject({}) do |mem, entry|
            # the old_type_id was casted to a fixnum
            # cheaper to change this here
            mem[entry['old_id'].to_i] = entry['new_id'].to_i
            mem
          end
        end

        @new_type_ids[old_type_id]
      end

      def set_empty_description(to_insert)
        to_insert['description'] = [nil, ''] unless to_insert.has_key?('description')
      end
    end
  end
end
