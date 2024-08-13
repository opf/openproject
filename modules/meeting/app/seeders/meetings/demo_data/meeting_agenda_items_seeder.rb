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

module Meetings
  module DemoData
    class MeetingAgendaItemsSeeder < ::BasicData::ModelSeeder
      self.model_class = MeetingAgendaItem
      self.seed_data_model_key = "meeting_agenda_items"

      ##
      #
      def initialize(_project, seed_data)
        super(seed_data)
      end

      def model_attributes(meeting_data)
        {
          item_type: item_type(meeting_data),
          title: title(meeting_data),
          notes: meeting_data["notes"],
          duration_in_minutes: meeting_data["duration"],
          author: seed_data.find_reference(meeting_data["author"]),
          presenter: seed_data.find_reference(meeting_data["presenter"]),
          meeting: seed_data.find_reference(meeting_data["meeting"]),
          work_package: seed_data.find_reference(meeting_data["work_package"])
        }
      end

      def item_type(meeting_data)
        if meeting_data["work_package"]
          MeetingAgendaItem.item_types[:work_package]
        else
          MeetingAgendaItem.item_types[:simple]
        end
      end

      def title(meeting_data)
        meeting_data["title"] unless meeting_data["work_package"]
      end
    end
  end
end
