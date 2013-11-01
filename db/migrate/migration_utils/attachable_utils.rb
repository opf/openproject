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
    MissingAttachment = Struct.new(:journaled_id,
                                   :attachment_id,
                                   :filename,
                                   :last_version)

    def repair_attachable_journal_entries(journal_type, legacy_journal_type)
      result = invalid_attachments(legacy_journal_type)

      repair_initial_journals(result, journal_type)
    end

    def remove_initial_journal_entries(journal_type, legacy_journal_type)
      result = invalid_attachments(legacy_journal_type)

      remove_initial_journals(result, journal_type)
    end

    def repair_initial_journals(result, journal_type)
      result.each do |m|
        journal_ids = affected_journal_ids(m.journaled_id, m.last_version, journal_type)

        journal_ids.each do |journal_id|
          insert <<-SQL
            INSERT INTO attachable_journals (journal_id, attachment_id, filename)
            VALUES (#{journal_id}, #{m.attachment_id}, '#{m.filename}')
          SQL
        end
      end
    end

    def remove_initial_journals(result, journal_type)
      result.each do |m|
        journal_ids = affected_journal_ids(m.journaled_id, m.last_version, journal_type)

        delete <<-SQL
          DELETE FROM attachable_journals
          WHERE journal_id IN (#{journal_ids.join(", ")})
        SQL
      end
    end

    private

    COLUMNS = ['changed_data', 'version', 'journaled_id']

    def invalid_attachments(legacy_journal_type)
      result = []

      update_column_values('legacy_journals',
                           COLUMNS,
                           find_work_packages_with_missing_initial_attachment(legacy_journal_type,
                                                                              result),
                           journal_filter(legacy_journal_type))

      result.flatten
    end

    def journal_filter(legacy_journal_type)
      "type = '#{legacy_journal_type}' AND changed_data LIKE '%attachments%'"
    end

    def find_work_packages_with_missing_initial_attachment(legacy_journal_type, result)
      Proc.new do |row|
        missing_entries = missing_initial_attachable_journals(legacy_journal_type,
                                                              row['id'],
                                                              row['journaled_id'],
                                                              row['version'],
                                                              row['changed_data'])

        result << missing_entries unless missing_entries.empty?

        UpdateResult.new(row, false)
      end
    end

    def missing_initial_attachable_journals(legacy_journal_type, journal_id, journaled_id, version, changed_data)
      removed_attachments = parse_attachment_removals(changed_data)

      missing_entries = missing_initial_attachment_entries(legacy_journal_type,
                                                           journaled_id,
                                                           version,
                                                           removed_attachments)

      missing_entries.map { |e| MissingAttachment.new(journaled_id,
                                                      e[:id],
                                                      e[:filename],
                                                      version.to_i - 1) }
    end

    ############################################
    # Matches attachment removals of the form: #
    #                                          #
    # attachments<id>:                         #
    # -                                        #
    # - <filename>                             #
    ############################################
    ATTACHMENT_REMOVAL_REGEX = /attachments_(?<id>\d+): \n-\s(?<filename>.+)\n-\s$/

    def parse_attachment_removals(changed_data)
      matches = changed_data.scan(ATTACHMENT_REMOVAL_REGEX)

      matches.each_with_object([]) { |m, l| l << { id: m[0], filename: m[1] } }
    end

    def missing_initial_attachment_entries(legacy_journal_type, journaled_id, version, attachments)
      attachments.select do |a|
        result = select_all <<-SQL
          SELECT version
          FROM legacy_journals
          WHERE journaled_id = #{journaled_id}
            AND type = '#{legacy_journal_type}'
            AND version < #{version}
            AND changed_data LIKE '%attachments#{a[:id]}:%'
            AND changed_data LIKE '%- #{a[:filename]}%'
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
