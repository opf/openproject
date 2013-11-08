#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/attachable_utils'

class RepairMessagesInitialAttachableJournal < ActiveRecord::Migration
  include Migration::Utils

  JOURNAL_TYPE = 'Message'

  def up
    say_with_time_silently "Repair message's initial attachable journals" do
      result = missing_message_attachments

      repair_journals(result)
    end
  end

  def down
    say_with_time_silently "Remove message's initial attachable journals" do
      result = missing_message_attachments

      remove_journals(result)
    end
  end

  private

  def missing_message_attachments
    result = select_all <<-SQL
      SELECT a.id, a.container_id, a.filename, last_version
      FROM attachments AS a
        JOIN (SELECT journable_id, MAX(version) AS last_version FROM journals
              WHERE journable_type = '#{JOURNAL_TYPE}'
              GROUP BY journable_id) AS j ON (a.container_id = j.journable_id)
      WHERE container_type = '#{JOURNAL_TYPE}'
    SQL

    result.each_with_object([]) do |row, a|
      a << MissingAttachment.new(row['container_id'],
                                 JOURNAL_TYPE,
                                 row['id'],
                                 row['filename'],
                                 row['last_version'])
    end
  end
end
