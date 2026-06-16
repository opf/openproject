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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"

module Pages
  class Sprints < Page
    attr_reader :project

    def initialize(project)
      super()
      @project = project
    end

    def path
      project_backlogs_sprints_path(project)
    end

    def within_sprints_table(&)
      within(sprint_table_selector, &)
    end

    def within_sprint_row(sprint, &)
      within_sprints_table do
        within(sprint_selector(sprint), &)
      end
    end

    def expect_sprints_in_order(sprints: [])
      raise ArgumentError, "sprints should not be empty" if sprints.empty?

      selectors = sprints.map { |s| sprint_selector(s) }

      within_sprints_table do
        expect(page).to have_css(selectors.join(" + "))
      end
    end

    def expect_sprint_row_values(sprint,
                                 name: sprint.name,
                                 status: I18n.t(:"activerecord.attributes.sprint.statuses.#{sprint.status}"),
                                 start_date: format_date(sprint.start_date),
                                 finish_date: format_date(sprint.finish_date),
                                 work_package_count: 0)
      within_sprint_row(sprint) do
        expect(page).to have_link(name, exact: true)
        expect(page).to have_css(".status", text: status)
        expect(page).to have_css(".start_date", text: start_date)
        expect(page).to have_css(".finish_date", text: finish_date)
        expect(page).to have_css(".work_package_count", text: work_package_count.to_s)
      end
    end

    def expect_sprint_present(sprint)
      within_sprints_table do
        expect(page).to have_css(sprint_selector(sprint))
      end
    end

    def expect_sprint_not_present(sprint)
      within_sprints_table do
        expect(page).to have_no_css(sprint_selector(sprint))
      end
    end

    def expect_pagination_range(from:, to:, total:) # rubocop:disable Naming/MethodParameterName
      within(".op-pagination") do
        expect(page).to have_css(".op-pagination--range", text: "(#{from} - #{to}/#{total})")
      end
    end

    def go_to_page!(number)
      within(".op-pagination--pages") do
        find(:link_or_button, text: number.to_s).click
      end

      wait_for_reload
    end

    def expect_empty_state(title: I18n.t(:label_nothing_display), description: I18n.t(:no_results_title_text))
      within_sprints_table do
        expect(page).to have_css("h2", text: title)
        expect(page).to have_text(description)
      end
    end

    def expect_sprint_name_link(sprint, href:)
      within_sprint_row(sprint) do
        expect(page).to have_link(sprint.name, href:)
      end
    end

    def expect_sprint_name_not_linked(sprint)
      within_sprint_row(sprint) do
        expect(page).to have_text(sprint.name)
        expect(page).to have_no_link(sprint.name)
      end
    end

    def sprint_table_selector
      test_selector("all-sprints-table")
    end

    def sprint_selector(sprint)
      "#sprint_#{sprint.id}"
    end

    def format_date(date)
      ApplicationController.helpers.format_date(date)
    end
  end
end
