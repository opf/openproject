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
  module WorkPackageMeetingsTabComponentStreams
    extend ActiveSupport::Concern

    included do
      def update_heading_component_via_turbo_stream(work_package: @work_package)
        update_via_turbo_stream(
          component: WorkPackageMeetingsTab::HeadingComponent.new(
            work_package:
          )
        )
      end

      def update_add_to_meeting_form_component_via_turbo_stream(meeting_agenda_item:, work_package: @work_package,
                                                                base_errors: nil)
        update_via_turbo_stream(
          component: WorkPackageMeetingsTab::AddWorkPackageToMeetingFormComponent.new(
            meeting_agenda_item:,
            work_package:,
            base_errors:
          ),
          status: :bad_request
        )
      end

      def update_index_component_via_turbo_stream(direction:, agenda_items_grouped_by_meeting:,
                                                  upcoming_meetings_count:, past_meetings_count:, work_package: @work_package)
        update_via_turbo_stream(
          component: WorkPackageMeetingsTab::IndexComponent.new(
            direction:,
            agenda_items_grouped_by_meeting:,
            upcoming_meetings_count:,
            past_meetings_count:,
            work_package:
          )
        )
      end

      def replace_tab_counter_via_turbo_stream(work_package: @work_package)
        replace_via_turbo_stream(
          component: WorkPackages::Details::UpdateCounterComponent.new(work_package:, menu_name: "meetings")
        )
      end
    end
  end
end
