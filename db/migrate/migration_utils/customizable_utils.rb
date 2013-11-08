# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'utils'

module Migration
  module Utils
    MissingCustomValue = Struct.new(:journaled_id,
                                    :journaled_type,
                                    :custom_field_id,
                                    :value,
                                    :last_version)

    def add_missing_customizable_journals
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
            VALUES (#{journal_id}, #{m.custom_field_id}, '#{m.value}')
          SQL
        end
      end
    end

    def remove_initial_journals(result)
      result.each do |m|
        journal_ids = affected_journal_ids(m.journaled_id, m.last_version, m.journaled_type)

        delete <<-SQL
          DELETE FROM customizable_journals
          WHERE journal_id IN (#{journal_ids.join(", ")})
        SQL
      end
    end

    private

    def missing_custom_values
      result = select_all <<-SQL
        SELECT * FROM
        (
          SELECT customized_id,
                 customized_type,
                 custom_value_journal.custom_field_id,
                 custom_value_journal.value,
                 last_version,
                 MAX(cj.id) AS cj_id FROM
          -- get all existing custom values and all journal entries for the customized thing
          (
            SELECT c.customized_id,
                   c.customized_type,
                   c.custom_field_id,
                   c.value AS value,
                   j.id AS journal_id,
                   MAX(j.version) AS last_version
            FROM custom_values AS c JOIN journals AS j
            ON c.customized_id = j.journable_id
            WHERE c.value <> ''
            GROUP BY c.customized_id, c.customized_type, c.custom_field_id, c.value, j.id, c.custom_field_id
          ) AS custom_value_journal
          -- join it with the customizable_journals and select the custom values that have no entry in that table
          LEFT JOIN customizable_journals AS cj
          ON custom_value_journal.journal_id = cj.journal_id
          GROUP BY customized_id,
                   customized_type,
                   custom_value_journal.custom_field_id,
                   custom_value_journal.value,
                   last_version
        ) AS custom_value_customizable_journal
        WHERE cj_id IS NULL;
      SQL

      result.collect { |row| MissingCustomValue.new(row['customized_id'],
                                                    row['customized_type'],
                                                    row['custom_field_id'],
                                                    row['value'],
                                                    row['last_version']) }
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

    def missing_initial_customizable_journals(legacy_journal_type, journal_id, journaled_id, version, changed_data)
      removed_customvalues = parse_customvalues_changes(changed_data)

      missing_entries = missing_initial_custom_value_entries(legacy_journal_type,
                                                           journaled_id,
                                                           version,
                                                           removed_customvalues)

      missing_entries.map { |e| MissingCustomValue.new(journaled_id,
                                                      nil,
                                                      e[:id],
                                                      e[:value],
                                                      version.to_i - 1) }
    end

    #############################################
    # Matches custom value changed of the form: #
    #                                           #
    # custom_values<id>:                        #
    # - "<old_value>"                           #
    # - "<new_value>"                           #
    #############################################
    CUSTOM_VALUE_CHANGE_REGEX = /custom_values(?<id>\d+): \n-\s"(?<old_value>.+)"\n-\s"(?<new_value>.*)"$/

    def parse_customvalues_changes(changed_data)
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
            AND changed_data LIKE '%- "#{c[:filename]}%"'
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

      result_set.collect { |r| r['id'] }
    end
  end
end
