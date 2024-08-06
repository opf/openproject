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
  class Taskboard < Page
    attr_reader :project, :sprint

    def initialize(project, sprint)
      super()
      @project = project
      @sprint = sprint
    end

    def expect_story(story)
      expect(page)
        .to have_selector(story_selector(story))
    end

    def expect_task(task)
      expect(page)
        .to have_css("#work_package_#{task.id}")
    end

    def expect_task_in_story_column(task, story, column)
      within ".story_#{story.id} td:nth-of-type(#{column + 2})" do
        expect(page)
          .to have_css("#work_package_#{task.id}")
      end
    end

    def expect_work_package_not_visible(work_package)
      expect(page)
        .to have_no_content(work_package.subject)
    end

    def expect_color_for_task(hex_color, task)
      expect(page)
        .to have_css("#work_package_#{task.id}[style='background-color:#{hex_color};']")
    end

    def add_task(story, attributes)
      find(".story_#{story.id} td.add_new").click

      change_attributes_in_modal(attributes)

      expect(page).to have_no_css(".ui-dialog")
      expect(page).to have_no_css("#work_package_")
    end

    def update_task(task, attributes)
      find("#work_package_#{task.id}").click

      change_attributes_in_modal(attributes)

      expect(page).to have_no_css(".ui-dialog")

      sleep(0.5)
    end

    def drag_to_task(dragged_task, target, before_or_after = :before)
      moved_element = find("#work_package_#{dragged_task.id}")
      target_element = find("#work_package_#{target.id}")

      drag_n_drop_element from: moved_element,
                          to: target_element,
                          offset_x: before_or_after == :before ? -40 : +30,
                          offset_y: 0
    end

    def drag_to_column(dragged_task, story, col_number)
      moved_element = find("#work_package_#{dragged_task.id}")
      target_element = find(".story_#{story.id} td:nth-of-type(#{col_number + 2})")

      moved_element.drag_to(target_element)
    end

    def path
      backlogs_project_sprint_taskboard_path(project, sprint)
    end

    private

    def story_selector(story)
      "#story_#{story.id}"
    end

    def change_attributes_in_modal(attributes)
      within ".ui-dialog" do
        attributes.each do |key, value|
          case key
          when :subject
            fill_in "Subject", with: value
          when :assignee
            select value, from: "Assignee"
          when :remaining_hours
            fill_in "Remaining work", with: value
          end
        end

        click_button "OK"
      end
    end
  end
end
