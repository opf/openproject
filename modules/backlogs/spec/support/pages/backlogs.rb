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
  class Backlogs < Page
    attr_reader :project

    def initialize(project)
      super()
      @project = project
    end

    def enter_edit_story_mode(story, text: nil)
      text ||= story.subject
      within_story(story) do
        find(:css, ".editable", text:).click
      end
    end

    def enter_edit_backlog_mode(backlog)
      within_backlog(backlog) do
        find(".start_date.editable").click
      end
    end

    def alter_attributes_in_edit_story_mode(story, attributes)
      edit_proc = ->(*) do
        attributes.each do |key, value|
          field_name = WorkPackage.human_attribute_name(key)
          case key
          when :subject, :story_points
            fill_in field_name, with: value
          when :status, :type
            select value, from: field_name
          else
            raise NotImplementedError
          end
        end
      end

      if story
        within_story(story, &edit_proc)
      else
        edit_proc.call
      end
    end

    def alter_attributes_in_edit_backlog_mode(backlog, attributes)
      within_backlog(backlog) do
        attributes.each do |key, value|
          case key
          when :name
            find("input[name=name]").set value
          when :start_date
            find("input[name=start_date]").set value
          when :effective_date
            find("input[name=effective_date]").set value
          else
            raise NotImplementedError
          end
        end
      end
    end

    def save_story_from_edit_mode(story)
      save_proc = ->(*) do
        field = find_field(disabled: false, match: :first)
        keys = [:return]
        keys << :return if field.tag_name == "select" # select field needs a second return key sent for some reason
        field.send_keys(*keys)

        expect(page).to have_no_field(WorkPackage.human_attribute_name(:subject))
      end

      if story
        within_story(story, &save_proc)
      else
        save_proc.call
      end
      wait_for_save_completion
    end

    def save_backlog_from_edit_mode(backlog)
      within_backlog(backlog) do
        find("input[name=name]").native.send_key :return

        expect(page)
          .to have_css(".start_date.editable")
      end
    end

    def wait_for_save_completion
      expect(page).to have_no_css(".ajax-indicator")
    end

    def edit_backlog(backlog, attributes)
      enter_edit_backlog_mode(backlog)

      alter_attributes_in_edit_backlog_mode(backlog, attributes)

      save_backlog_from_edit_mode(backlog)
    end

    def edit_story(story, attributes)
      enter_edit_story_mode(story)

      alter_attributes_in_edit_story_mode(story, attributes)

      save_story_from_edit_mode(story)
    end

    def edit_new_story(attributes)
      within(".story.editing") do
        alter_attributes_in_edit_story_mode(nil, attributes)

        save_story_from_edit_mode(nil)
      end
    end

    def click_in_backlog_menu(backlog, item_name)
      within_backlog_menu(backlog) do |menu|
        menu.find(".item", text: item_name).click
      end
    end

    def drag_in_sprint(moved, target, before: true)
      moved_element = find(story_selector(moved))
      target_element = find(story_selector(target))

      drag_n_drop_element from: moved_element, to: target_element, offset_x: 0, offset_y: before ? -5 : +10
      wait_for_save_completion
    end

    def fold_backlog(backlog)
      within_backlog(backlog) do
        find(".toggler").click
      end
    end

    def expect_sprint(sprint)
      expect(page)
        .to have_css("#sprint_backlogs_container #{backlog_selector(sprint)}")
    end

    def expect_backlog(sprint)
      expect(page)
        .to have_css("#owner_backlogs_container #{backlog_selector(sprint)}")
    end

    def expect_story_in_sprint(story, sprint)
      within_backlog(sprint) do
        expect(page)
          .to have_selector(story_selector(story).to_s)
      end
    end

    def expect_story_not_in_sprint(story, sprint)
      within_backlog(sprint) do
        expect(page)
          .to have_no_selector(story_selector(story).to_s)
      end
    end

    def expect_for_story(story, attributes)
      within_story(story) do
        attributes.each do |key, value|
          case key
          when :subject
            expect(page)
              .to have_css("div.subject", text: value)
          when :status
            expect(page)
              .to have_css("div.status_id", text: value)
          when :type
            expect(page)
              .to have_css("div.type_id", text: value)
          else
            raise NotImplementedError
          end
        end
      end
    end

    def expect_story_link_to_wp_page(story)
      within_story(story) do
        expect(page)
          .to have_link(story.id, href: work_package_path(story))
      end
    end

    def expect_status_options(story, statuses)
      within_story(story) do
        expect(all(".status_id option").map { |n| n.text.strip })
          .to match_array(statuses.map(&:name))
      end
    end

    def expect_velocity(backlog, velocity)
      within("#backlog_#{backlog.id} .velocity") do
        expect(page)
          .to have_content(velocity.to_s)
      end
    end

    def expect_stories_in_order(backlog, *stories)
      within_backlog(backlog) do
        ids = stories.map { |s| "story_#{s.id}" }
        existing_ids_in_order = all(ids.map { |id| "##{id}" }.join(", ")).pluck(:id)

        expect(existing_ids_in_order)
          .to eql(ids)
      end
    end

    def expect_in_backlog_menu(backlog, item_name)
      within_backlog(backlog) do
        find(".header .menu-trigger").click

        expect(page)
          .to have_css(".header .backlog-menu .item", text: item_name)

        # Close it again for next test
        find(".header .menu-trigger").click
      end
    end

    def expect_and_dismiss_error(message)
      within ".ui-dialog" do
        expect(page)
          .to have_content message

        click_button("OK")
      end
    end

    def path
      backlogs_project_backlogs_path(project)
    end

    def within_backlog_menu(backlog, &)
      within_backlog(backlog) do
        menu = find(".backlog-menu")
        menu.click

        yield menu
      end
    end

    private

    def within_story(story, &)
      within(story_selector(story), &)
    end

    def within_backlog(backlog, &)
      within(backlog_selector(backlog), &)
    end

    def backlog_selector(backlog)
      "#backlog_#{backlog.id}"
    end

    def story_selector(story)
      "#story_#{story.id}"
    end

    def toast_type
      :ruby
    end
  end
end
