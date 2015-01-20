#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

    unless migrator.missing_type_ids.empty?
      puts 'Cannot resolve new type ids for all journals!'\
           "\n\n"\
           'The following list contains all legacy planning element '\
           'type ids for which no new type id exists. Furthermore, '\
           'the list contains all journal ids for which no new type '\
           'id exists.'\
           "\n\n"\
           "#{migrator.missing_type_ids}"\
           "\n\n"\
           "The type id is set to '0' for all journals containing a "\
           'planning element type id for which no type id exists.'\
           "\n\n\n"
    end

    unless migrator.missing_journaled_ids.empty?
      puts 'Cannot resolve work package ids for all journals!'\
           "\n\n"\
           'The following list contains all legacy planning element '\
           'ids for which no new work package id exists. Furthermore,'\
           ' the list contains all journal ids for which no new'\
           'work package id exists.'\
           "\n\n"\
           "#{migrator.missing_journaled_ids}"\
           "\n\n"\
           "The work package id is set to '0' for all journals "\
           'containing a planning element type id for which no type '\
           'id exists.'
      "\n\n\n"
    end
  end

  def down
    migrator.remove_journals_derived_from_legacy_journals 'customizable_journals',
                                                          'attachable_journals'
  end

  def migrator
    @migrator ||= Migration::LegacyJournalMigrator.new 'Timelines_PlanningElementJournal', 'work_package_journals' do
      extend Migration::JournalMigratorConcerns::Attachable
      extend Migration::JournalMigratorConcerns::Customizable

      self.journable_class = 'WorkPackage'

      def migrate(legacy_journal)
        update_journaled_id(legacy_journal)

        super
      end

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)
        update_type_id(to_insert, journal_id)

        set_empty_description(to_insert)

        migrate_attachments(to_insert, legacy_journal, journal_id)

        migrate_custom_values(to_insert, legacy_journal, journal_id)
      end

      def update_journaled_id(legacy_journal)
        legecy_journal_id = legacy_journal['id']
        old_journaled_id = legacy_journal['journaled_id']
        new_journaled_id = new_journaled_id_for_old(old_journaled_id)

        if new_journaled_id.nil?
          add_missing_journaled_id_for_legacy_journal_id(old_journaled_id, legecy_journal_id)

          new_journaled_id = 0
        end

        legacy_journal['journaled_id'] = new_journaled_id
      end

      def update_type_id(to_insert, journal_id)
        return if to_insert['planning_element_type_id'].nil? ||
                  to_insert['planning_element_type_id'].last.nil?

        old_type_id = to_insert['planning_element_type_id'].last

        new_type_id = new_type_id_for_old(old_type_id)

        if new_type_id.nil?
          add_missing_type_id_for_journal_id(old_type_id, journal_id)

          new_type_id = 0
        end

        to_insert['type_id'] = [nil, new_type_id]
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

      def missing_journaled_ids
        @missing_journaled_ids ||= {}
      end

      def add_missing_journaled_id_for_legacy_journal_id(old_journaled_id, legacy_journal_id)
        missing_journaled_ids[old_journaled_id] = [] unless missing_journaled_ids.has_key? old_journaled_id
        missing_journaled_ids[old_journaled_id] << legacy_journal_id
      end

      def missing_type_ids
        @missing_type_ids ||= {}
      end

      def add_missing_type_id_for_journal_id(old_type_id, journal_id)
        missing_type_ids[old_type_id] = [] unless missing_type_ids.has_key? old_type_id
        missing_type_ids[old_type_id] << journal_id
      end
    end
  end
end
