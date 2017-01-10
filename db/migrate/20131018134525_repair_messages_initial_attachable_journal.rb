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

require_relative 'migration_utils/attachable_utils'

class RepairMessagesInitialAttachableJournal < ActiveRecord::Migration[4.2]
  include Migration::Utils
  include Migration::Utils::AttachableUtils

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
