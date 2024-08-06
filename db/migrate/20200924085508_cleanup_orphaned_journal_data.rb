#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class CleanupOrphanedJournalData < ActiveRecord::Migration[6.0]
  def up
    cleanup_orphaned_journals("attachable_journals")
    cleanup_orphaned_journals("customizable_journals")
    cleanup_orphaned_journals("attachment_journals")
    cleanup_orphaned_journals("changeset_journals")
    cleanup_orphaned_journals("message_journals")
    cleanup_orphaned_journals("news_journals")
    cleanup_orphaned_journals("wiki_content_journals")
    cleanup_orphaned_journals("work_package_journals")
  end

  # No down needed as this only cleans up data that should have been deleted anyway.

  private

  def cleanup_orphaned_journals(table)
    execute <<~SQL.squish
      DELETE
      FROM
        #{table}
      WHERE
        #{table}.id IN (
          SELECT
            #{table}.id
          FROM
            #{table}
          LEFT OUTER JOIN
            journals
          ON
            journals.id = #{table}.journal_id
          WHERE
            journals.id IS NULL
        )
    SQL
  end
end
