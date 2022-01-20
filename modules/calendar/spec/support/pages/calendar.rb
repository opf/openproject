#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require 'support/pages/page'

module Pages
  class Calendar < ::Pages::Page
    attr_reader :project,
                :filters

    def initialize(project)
      super()

      @project = project
      @filters = ::Components::WorkPackages::Filters.new
    end

    def path
      project_calendar_path(project)
    end

    def add_item(start_date, end_date)
      start_container = date_container start_date
      end_container = date_container end_date

      drag_n_drop_element(from: start_container, to: end_container)

      ::Pages::SplitWorkPackageCreate.new project: project
    end

    def resize_date(work_package, date, end_date: true)
      wp_strip = event(work_package)

      page
        .driver
        .browser
        .action
        .move_to(wp_strip.native)
        .perform

      selector = end_date ? '.fc-event-resizer-end' : '.fc-event-resizer-start'
      resizer = wp_strip.find(selector)
      end_container = date_container date

      drag_n_drop_element(from: resizer, to: end_container)
    end

    def drag_event(work_package, target)
      start_container = event(work_package)
      end_container = date_container target

      drag_n_drop_element(from: start_container, to: end_container)
    end

    def date_container(date)
      str = date.respond_to?(:iso8601) ? date.iso8601 : date.to_s
      page.find(".fc-day[data-date='#{str}'] .fc-daygrid-day-frame")
    end

    def expect_title(title = 'Unnamed calendar')
      expect(page).to have_selector '.editable-toolbar-title--fixed', text: title
    end

    def expect_event(work_package, present: true)
      expect(page).to have_conditional_selector(present, '.fc-event', text: work_package.subject, wait: 10)
    end

    def open_split_view(work_package)
      page
        .find('.fc-event', text: work_package.subject)
        .click

      ::Pages::SplitWorkPackage.new(work_package, project)
    end

    def event(work_package)
      page.find('.fc-event', text: work_package.subject)
    end

    def expect_wp_not_resizable(work_package)
      expect(page).to have_selector('.fc-event:not(.fc-event-resizable)', text: work_package.subject)
    end

    def expect_wp_not_draggable(work_package)
      expect(page).to have_selector('.fc-event:not(.fc-event-draggable)', text: work_package.subject)
    end
  end
end
