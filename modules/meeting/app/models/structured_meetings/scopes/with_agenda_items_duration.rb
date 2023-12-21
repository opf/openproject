# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

module StructuredMeetings::Scopes
  module WithAgendaItemsDuration
    extend ActiveSupport::Concern

    class_methods do
      def with_agenda_items_duration
        StructuredMeeting
          .from("#{Meeting.table_name} meetings")
          .joins("LEFT JOIN (#{agenda_items_sums_sql}) agenda_items_sums ON meetings.id = agenda_items_sums.meeting_id")
          .select('meetings.*')
          .select('agenda_items_sums.total_duration AS agenda_items_duration')
      end

      private

      def agenda_items_sums_sql
        <<~SQL.squish
          SELECT agenda_items.meeting_id, SUM(agenda_items.duration_in_minutes) AS total_duration
          FROM #{MeetingAgendaItem.table_name} agenda_items
          GROUP BY agenda_items.meeting_id
        SQL
      end
    end

    def agenda_items_duration
      @agenda_items_duration ||= begin
        value = read_attribute(:agenda_items_duration) ||
          self.class.with_agenda_items_duration.where(id:).pick('agenda_items_sums.total_duration')

        value.to_f
      end
    end
  end
end
