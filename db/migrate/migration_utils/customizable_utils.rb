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

require_relative 'utils'

module Migration::Utils
  module CustomizableUtils
    MissingCustomValue = Struct.new(:journaled_id,
                                    :journaled_type,
                                    :custom_field_id,
                                    :value,
                                    :last_version)

    def add_missing_customizable_journals
      delete_invalid_work_package_custom_values

      result = missing_custom_values

      repair_journals(result)
    end

    def repair_customizable_journal_entries(journal_type, legacy_journal_type)
      result = invalid_custom_values(legacy_journal_type)

      result.map { |m| m.journaled_type = journal_type }

      repair_journals(result)
    end

    def remove_customizable_journal_entries(journal_type, legacy_journal_type)
      result = invalid_custom_values(legacy_journal_type)

      result.map { |m| m.journaled_type = journal_type }

      remove_initial_journals(result)
    end

    def repair_journals(result)
      result.each do |m|
        journal_ids = affected_journal_ids(m.journaled_id, m.last_version, m.journaled_type)

        journal_ids.each do |journal_id|
          insert <<-SQL
            INSERT INTO customizable_journals (journal_id, custom_field_id, value)
            VALUES (#{journal_id}, #{m.custom_field_id}, #{quote_value(m.value)})
          SQL
        end
      end
    end

    def remove_initial_journals(result)
      result.each do |m|
        journal_ids = affected_journal_ids(m.journaled_id, m.last_version, m.journaled_type)

        delete <<-SQL
          DELETE FROM customizable_journals
          WHERE journal_id IN (#{journal_ids.join(', ')})
        SQL
      end
    end

    private

    # Removes all work package custom values that are not referenced by the
    # work package's project AND type.
    def delete_invalid_work_package_custom_values
      if mysql?
        delete <<-SQL
          DELETE cv.* FROM custom_values AS cv
              JOIN work_packages AS w ON (w.id = cv.customized_id AND cv.customized_type = 'WorkPackage')
              JOIN custom_fields AS cf ON (cv.custom_field_id = cf.id)
              JOIN projects AS p ON (w.project_id = p.id)
              LEFT JOIN custom_fields_projects AS cfp ON (cv.custom_field_id = cfp.custom_field_id AND w.project_id = cfp.project_id)
              LEFT JOIN custom_fields_types AS cft ON (cv.custom_field_id = cft.custom_field_id AND w.type_id = cft.type_id)
          WHERE (cfp.project_id IS NULL AND cf.is_for_all = FALSE)
            OR cft.type_id IS NULL
        SQL
      else
        delete <<-SQL
          DELETE FROM custom_values AS cvd
          WHERE EXISTS
          (
            SELECT w.id, cf.id, cfp.project_id, p.name, cft.type_id
            FROM work_packages AS w
              JOIN custom_values AS cv ON (w.id = cv.customized_id AND cv.customized_type = 'WorkPackage')
              JOIN custom_fields AS cf ON (cv.custom_field_id = cf.id)
              JOIN projects AS p ON (w.project_id = p.id)
              LEFT JOIN custom_fields_projects AS cfp ON (cv.custom_field_id = cfp.custom_field_id AND w.project_id = cfp.project_id)
              LEFT JOIN custom_fields_types AS cft ON (cv.custom_field_id = cft.custom_field_id AND w.type_id = cft.type_id)
            WHERE (cfp.project_id IS NULL AND cf.is_for_all = FALSE
              OR cft.type_id IS NULL)
              AND cv.id = cvd.id
           );
        SQL
      end
    end

    def missing_custom_values
      result = select_all <<-SQL
        SELECT tmp.customized_id,
               tmp.customized_type,
               tmp.custom_field_id,
               tmp.current_value,
               tmp.last_version,
               tmp.journal_value
        FROM (
          SELECT cv.customized_id,
                 cv.customized_type,
                 cv.custom_field_id,
                 cv.value AS current_value,
                 MAX(j.version) AS last_version,
                 cj.value AS journal_value
          FROM custom_values AS cv
            JOIN journals AS j ON (cv.customized_id = j.journable_id AND cv.customized_type = j.journable_type AND cv.value <> '')
            LEFT JOIN customizable_journals AS cj ON (j.id = cj.journal_id AND cv.custom_field_id = cj.custom_field_id)
          GROUP BY cv.customized_id,
             cv.customized_type,
             cv.custom_field_id,
             cv.value,
               cj.value
        ) AS tmp
        WHERE tmp.last_version = (SELECT MAX(version) AS last_version
                                  FROM journals AS j
                WHERE j.journable_id = tmp.customized_id AND j.journable_type = tmp.customized_type
                GROUP BY j.journable_id, j.journable_type)
          AND tmp.journal_value IS NULL
      SQL

      result.map { |row|
        MissingCustomValue.new(row['customized_id'],
                               row['customized_type'],
                               row['custom_field_id'],
                               row['current_value'],
                               row['last_version'])
      }
    end

    COLUMNS = ['changed_data', 'version', 'journaled_id']

    def invalid_custom_values(legacy_journal_type)
      result = []

      update_column_values('legacy_journals',
                           COLUMNS,
                           find_work_package_with_missing_initial_custom_values(legacy_journal_type,
                                                                                result),
                           journal_filter(legacy_journal_type))

      result.flatten
    end

    def journal_filter(legacy_journal_type)
      "type = '#{legacy_journal_type}' AND changed_data LIKE '%custom_values%'"
    end

    def find_work_package_with_missing_initial_custom_values(legacy_journal_type, result)
      Proc.new do |row|
        missing_entries = missing_initial_customizable_journals(legacy_journal_type,
                                                                row['id'],
                                                                row['journaled_id'],
                                                                row['version'],
                                                                row['changed_data'])

        result << missing_entries unless missing_entries.empty?

        UpdateResult.new(row, false)
      end
    end

    def missing_initial_customizable_journals(legacy_journal_type, _journal_id, journaled_id, version, changed_data)
      removed_customvalues = parse_custom_value_changes(changed_data)

      missing_entries = missing_initial_custom_value_entries(legacy_journal_type,
                                                             journaled_id,
                                                             version,
                                                             removed_customvalues)

      missing_entries.map { |e|
        MissingCustomValue.new(journaled_id,
                               nil,
                               e[:id],
                               e[:value],
                               version.to_i - 1)
      }
    end

    #############################################
    # Matches custom value changed of the form: #
    #                                           #
    # custom_values<id>:                        #
    # - "<old_value>"                           #
    # - "<new_value>"                           #
    #############################################
    CUSTOM_VALUE_CHANGE_REGEX = /custom_values(?<id>\d+): \n-\s"(?<old_value>.*)"\n-\s"(?<new_value>.*)"$/

    def parse_custom_value_changes(changed_data)
      matches = changed_data.scan(CUSTOM_VALUE_CHANGE_REGEX)

      matches.each_with_object([]) { |m, l| l << { id: m[0], value: m[1] } }
    end

    def missing_initial_custom_value_entries(legacy_journal_type, journaled_id, version, custom_values)
      custom_values.select do |c|
        result = select_all <<-SQL
          SELECT version
          FROM legacy_journals
          WHERE journaled_id = #{journaled_id}
            AND type = '#{legacy_journal_type}'
            AND version < #{version}
            AND changed_data LIKE '%custom_values#{c[:id]}:%'
            AND changed_data LIKE '%- "#{c[:value]}%"'
          ORDER BY version
        SQL

        result.empty?
      end
    end

    def affected_journal_ids(journaled_id, last_version, journal_type)
      result_set = select_all <<-SQL
        SELECT id
        FROM journals
        WHERE journable_id = #{journaled_id}
          AND journable_type = '#{journal_type}'
          AND version <= #{last_version}
      SQL

      result_set.map { |r| r['id'] }
    end
  end
end
