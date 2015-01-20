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
  module AttachableUtils
    MissingAttachment = Struct.new(:journaled_id,
                                   :journaled_type,
                                   :attachment_id,
                                   :filename,
                                   :last_version)

    def add_missing_attachable_journals
      result = missing_attachments

      repair_journals(result)
    end

    def repair_attachable_journal_entries(journal_type, legacy_journal_type)
      result = invalid_attachments(legacy_journal_type)

      result.map { |m| m.journaled_type = journal_type }

      repair_journals(result)
    end

    def remove_initial_journal_entries(journal_type, legacy_journal_type)
      result = invalid_attachments(legacy_journal_type)

      result.map { |m| m.journaled_type = journal_type }

      remove_initial_journals(result)
    end

    def repair_journals(result)
      result.each do |m|
        journal_ids = affected_journal_ids(m.journaled_id, m.last_version, m.journaled_type)

        journal_ids.each do |journal_id|
          insert <<-SQL
            INSERT INTO attachable_journals (journal_id, attachment_id, filename)
            VALUES (#{journal_id}, #{m.attachment_id}, '#{m.filename}')
          SQL
        end
      end
    end

    def remove_initial_journals(result)
      result.each do |m|
        journal_ids = affected_journal_ids(m.journaled_id, m.last_version, m.journaled_type)

        delete <<-SQL
          DELETE FROM attachable_journals
          WHERE journal_id IN (#{journal_ids.join(', ')})
        SQL
      end
    end

    private

    def missing_attachments
      result = select_all <<-SQL
        SELECT * FROM (
          SELECT a.container_id AS journaled_id, a.container_type AS journaled_type, a.id AS attachment_id, a.filename, MAX(aj.id) AS aj_id, MAX(j.version) AS last_version
          FROM attachments AS a JOIN journals AS j
            ON (a.container_id = j.journable_id AND a.container_type = j.journable_type) LEFT JOIN attachable_journals AS aj
            ON (a.id = aj.attachment_id)
          GROUP BY a.container_id, a.container_type, a.id, a.filename
          ) AS tmp
        WHERE aj_id IS NULL
      SQL

      result.map { |row|
        MissingAttachment.new(row['journaled_id'],
                              row['journaled_type'],
                              row['attachment_id'],
                              row['filename'],
                              row['last_version'])
      }
    end

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

    def missing_initial_attachable_journals(legacy_journal_type, _journal_id, journaled_id, version, changed_data)
      removed_attachments = parse_attachment_removals(changed_data)

      missing_entries = missing_initial_attachment_entries(legacy_journal_type,
                                                           journaled_id,
                                                           version,
                                                           removed_attachments)

      missing_entries.map { |e|
        MissingAttachment.new(journaled_id,
                              nil,
                              e[:id],
                              e[:filename],
                              version.to_i - 1)
      }
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

      result_set.map { |r| r['id'] }
    end
  end
end
