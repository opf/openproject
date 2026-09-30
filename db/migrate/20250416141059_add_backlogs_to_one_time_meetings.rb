# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class AddBacklogsToOneTimeMeetings < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      INSERT INTO meeting_sections (meeting_id, backlog, title, position, created_at, updated_at)
      SELECT m.id, true, '', 0, NOW(), NOW()
      FROM meetings m
      WHERE (
        m.recurring_meeting_id IS NULL
        OR m.template = true
      )
    SQL
  end

  def down
    execute <<~SQL.squish
      DELETE FROM meeting_agenda_items
      WHERE meeting_section_id IN (SELECT id FROM meeting_sections WHERE backlog = true)
    SQL

    execute <<~SQL.squish
      DELETE FROM meeting_sections
      WHERE backlog = true
    SQL
  end
end
