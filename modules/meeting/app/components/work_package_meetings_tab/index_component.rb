#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module WorkPackageMeetingsTab
  class IndexComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def initialize(work_package:, agenda_items_grouped_by_meeting:, upcoming_meetings_count:, past_meetings_count:,
                   direction: :upcoming)
      super

      @work_package = work_package
      @agenda_items_grouped_by_meeting = agenda_items_grouped_by_meeting
      @direction = direction
      @upcoming_meetings_count = upcoming_meetings_count
      @past_meetings_count = past_meetings_count
    end

    def call
      content_tag("turbo-frame", id: "work-package-meetings-tab-content") do
        frame_content_partial
      end
    end

    private

    def frame_content_partial
      component_wrapper do
        flex_layout do |flex|
          flex.with_row do
            render(WorkPackageMeetingsTab::HeadingComponent.new(work_package: @work_package))
          end
          flex.with_row(mt: 3) do
            tabbed_navigation_partial
          end
          flex.with_row do
            render(WorkPackageMeetingsTab::ListComponent.new(
                     agenda_items_grouped_by_meeting: @agenda_items_grouped_by_meeting,
                     direction: @direction
                   ))
          end
        end
      end
    end

    def tabbed_navigation_partial
      render(Primer::Alpha::TabNav.new(label: "label")) do |component|
        component.with_tab(selected: @direction == :upcoming,
                           href: work_package_meetings_tab_index_path(@work_package,
                                                                      direction: :upcoming)) do |tab|
          tab.with_text { t("label_upcoming_meetings_short") }
          tab.with_counter(count: @upcoming_meetings_count)
        end
        component.with_tab(selected: @direction == :past,
                           href: work_package_meetings_tab_index_path(@work_package,
                                                                      direction: :past)) do |tab|
          tab.with_text { t("label_past_meetings_short") }
          tab.with_counter(count: @past_meetings_count)
        end
      end
    end
  end
end
