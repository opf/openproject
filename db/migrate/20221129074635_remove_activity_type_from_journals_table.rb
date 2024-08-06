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

class RemoveActivityTypeFromJournalsTable < ActiveRecord::Migration[7.0]
  def up
    remove_column :journals, :activity_type
  end

  def down
    add_column :journals, :activity_type, :string

    execute <<-SQL.squish
      UPDATE
        journals
      SET
        activity_type =
          CASE
          WHEN journable_type = 'Attachment' THEN 'attachments'
          WHEN journable_type = 'Budget' THEN 'budgets'
          WHEN journable_type = 'Changeset' THEN 'changesets'
          WHEN journable_type = 'Document' THEN 'documents'
          WHEN journable_type = 'Meeting' THEN 'meetings'
          WHEN journable_type = 'Message' THEN 'messages'
          WHEN journable_type = 'News' THEN 'news'
          WHEN journable_type = 'TimeEntry' THEN 'time_entries'
          WHEN journable_type = 'WikiContent' THEN 'wiki_edits'
          WHEN journable_type = 'WorkPackage' THEN 'work_packages'
          END
      WHERE journable_type != 'MeetingContent'
    SQL

    execute <<-SQL.squish
      UPDATE
        journals
      SET
        activity_type =
          CASE
          WHEN meeting_contents.type = 'MeetingMinutes' THEN 'meeting_minutes'
          WHEN meeting_contents.type = 'MeetingAgenda' THEN 'meeting_agenda'
          ELSE 'meetings'
          END
      FROM meeting_contents
      WHERE journable_type = 'MeetingContent'
        AND journable_id = meeting_contents.id
    SQL
  end
end
