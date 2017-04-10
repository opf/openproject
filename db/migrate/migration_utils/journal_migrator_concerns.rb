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

module Migration
  module JournalMigratorConcerns
    module Attachable
      def migrate_attachments(to_insert, legacy_journal, journal_id)
        attachments = to_insert.keys.select { |d| d =~ attachment_key_regexp }
        attachments = remove_attachments_deleted_in_current_version attachments, to_insert

        attachments.each do |key|
          attachment_id = attachment_key_regexp.match(key)[1]

          # if an attachment was added the value contains something like:
          # [nil, "blubs.png"]
          # if it was removed the value is something like
          # ["blubs.png", nil]
          removed_filename, added_filename = *to_insert[key]
          if added_filename && !removed_filename
            query = <<-SQL
              SELECT *
              FROM #{attachable_table_name} AS a
              WHERE a.journal_id = #{quote_value(journal_id)} AND a.attachment_id = #{attachment_id};
            SQL

            # The attachment was added
            attachable = ActiveRecord::Base.connection.select_all(query).to_a
            if attachable.size > 1
              raise AmbiguousAttachableJournalError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
                It appears there are ambiguous attachable journal data.
                Please make sure attachable journal data are consistent and
                that the unique constraint on journal_id and attachment_id
                is met.
              MESSAGE
            elsif attachable.size == 0
              db_execute <<-SQL
                INSERT INTO #{attachable_table_name}(journal_id, attachment_id, filename)
                VALUES (#{quote_value(journal_id)}, #{quote_value(attachment_id)}, #{quote_value(added_filename)});
              SQL
            end
          elsif removed_filename && !added_filename
            # The attachment was removed
            # we need to make certain that no subsequent journal adds an attachable_journal
            # for this attachment
            to_insert.delete_if { |k, _v| k =~ /attachments_?#{attachment_id}/ }
          else
            raise InvalidAttachableJournalError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
              There is a journal entry for an attachment but neither the old nor the new value contains anything:
              #{to_insert}
              #{legacy_journal}
            MESSAGE
          end
        end
      end

      # sometimes there are attachments, which were deleted in a later journal entry
      # there is not need to add those attachments, so we filter them out here
      def remove_attachments_deleted_in_current_version(attachments, journal_to_insert)
        deleted_attachments = attachments.select { |key|
          # journal_to_insert[key] is of the form
          # [nil, "filename.ext"] when the attachment was added
          # ["filename.ext", nil] when the attachment was removed
          journal_to_insert[key].first
        }
        attachments.reject do |key|
          deleted_attachments.any? { |del_key| key =~ /attachments#{del_key[attachment_key_regexp, 1]}/ }
        end
      end

      def attachable_table_name
        quoted_table_name('attachable_journals')
      end

      def attachment_key_regexp
        # Attachment journal entries can be written in two ways:
        # attachments123 if the attachment was added
        # attachments_123 if the attachment was removed
        @attachment_key_regexp ||= /attachments_?(\d+)\z/
      end
    end

    module Customizable
      def migrate_custom_values(to_insert, _legacy_journal, journal_id)
        keys = to_insert.keys
        values = to_insert.values
        custom_values = keys.select { |d| d =~ /custom_values.*/ }
        custom_values.each do |k|
          custom_field_id = k.split('_values').last.to_i
          value = values[keys.index k].last
          customizable = db_select_all <<-SQL
            SELECT *
            FROM #{customizable_table_name} AS a
            WHERE a.journal_id = #{quote_value(journal_id)} AND a.custom_field_id = #{custom_field_id};
          SQL

          if customizable.size > 1
            raise AmbiguousCustomizableJournalError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
              It appears there are ambiguous customizable journal
              data. Please make sure customizable journal data are
              consistent and that the unique constraint on journal_id and
              custom_field_id is met.
            MESSAGE
          elsif customizable.size == 0
            db_execute <<-SQL
              INSERT INTO #{customizable_table_name}(journal_id, custom_field_id, value)
              VALUES (#{quote_value(journal_id)}, #{quote_value(custom_field_id)}, #{quote_value(value)});
            SQL
          end
        end
      end

      def customizable_table_name
        quoted_table_name('customizable_journals')
      end
    end
  end
end
