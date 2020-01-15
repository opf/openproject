#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'
require 'support/pages/work_packages/work_packages_table'

module Pages
  class WorkPackagesTimeline < WorkPackagesTable
    def toggle_timeline
      ::Components::WorkPackages::DisplayRepresentation.new.switch_to_gantt_layout
    end

    def timeline_row_selector(wp_id)
      ".wp-row-#{wp_id}-timeline"
    end

    def timeline_container
      '.work-packages-tabletimeline--timeline-side'
    end

    def expect_row_count(num)
      within(timeline_container) do
        expect(page).to have_selector('.wp-timeline-cell', count: num)
      end
    end

    def expect_work_package_listed(*work_packages)
      super(*work_packages)

      if page.has_selector?('#wp-view-toggle-button', text: 'Gantt')
        within(timeline_container) do
          work_packages.each do |wp|
            expect(page).to have_selector(".wp-row-#{wp.id}-timeline", visible: true)
          end
        end
      end
    end

    def expect_work_package_not_listed(*work_packages)
      super(*work_packages)

      if page.has_selector?('#wp-view-toggle-button', text: 'Gantt')
        within(timeline_container) do
          work_packages.each do |wp|
            expect(page).to have_no_selector(".wp-row-#{wp.id}-timeline", visible: true)
          end
        end
      end
    end

    def expect_work_package_order(*ids)
      retry_block do
        rows = page.all('.wp-table-timeline--body .wp--row')
        expected = ids.map { |el| el.is_a?(WorkPackage) ? el.id.to_s : el.to_s }
        found = rows.map { |el| el['data-work-package-id'] }

        raise "Order is incorrect: #{found.inspect} != #{expected.inspect}" unless found == expected
      end
    end

    def expect_timeline!(open: true)
      if open
        expect(page).to have_selector('#wp-view-toggle-button', text: 'Gantt')
        expect(page).to have_selector('.wp-table-timeline--container .wp-timeline-cell')
      else
        expect(page).to have_no_selector('#wp-view-toggle-button', text: 'Gantt')
        expect(page).to have_no_selector('.wp-table-timeline--container .wp-timeline-cell', visible: true)
      end
    end

    def timeline_row(wp_id)
      ::Components::Timelines::TimelineRow.new  page.find(timeline_row_selector(wp_id))
    end

    def zoom_in_button
      page.find('#work-packages-timeline-zoom-in-button')
    end

    def zoom_in
      zoom_in_button.click
    end

    def zoom_out
      zoom_out_button.click
    end

    def zoom_out_button
      page.find('#work-packages-timeline-zoom-out-button')
    end

    def autozoom
      page.find('#work-packages-timeline-zoom-auto-button').click
    end

    def expect_zoom_at(value)
      unless ::Query.timeline_zoom_levels.key?(value)
        raise ArgumentError, "Invalid value"
      end

      expect(page).to have_selector(".wp-table-timeline--header-inner[data-current-zoom-level='#{value}']")
    end

    def expect_timeline_element(work_package)
      type = work_package.milestone? ? :milestone : :bar
      expect(page).to have_selector(".wp-row-#{work_package.id}-timeline .timeline-element.#{type}")
    end

    def expect_timeline_relation(from, to)
      within(timeline_container) do
        expect(page).to have_selector(".relation-line.__tl-relation-#{from.id}.__tl-relation-#{to.id}", minimum: 1)
      end
    end

    def expect_no_timeline_relation(from, to)
      within(timeline_container) do
        expect(page).to have_no_selector(".relation-line.__tl-relation-#{from.id}.__tl-relation-#{to.id}")
      end
    end

    def expect_no_relations
      within(timeline_container) do
        expect(page).to have_no_selector(".relation-line")
      end
    end

    def expect_hidden_row(work_package)
      expect(page).to have_selector(".wp-row-#{work_package.id}-timeline", visible: :hidden)
    end
  end
end
