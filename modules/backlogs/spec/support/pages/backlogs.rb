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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  class Backlogs < Page
    attr_reader :project

    def initialize(project)
      super()
      @project = project
    end

    def enter_edit_story_mode(story)
      within_story(story) do
        find('*', text: story.subject).click
      end
    end

    def enter_edit_backlog_mode(backlog)
      within_backlog(backlog) do
        find('.start_date.editable').click
      end
    end

    def alter_attributes_in_edit_story_mode(story, attributes)
      edit_proc = -> do
        attributes.each do |key, value|
          case key
          when :subject
            fill_in 'subject', with: value
          when :story_points
            fill_in 'story points', with: value
          when :status
            select value, from: 'status'
          when :type
            select value, from: 'type'
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
            find('input[name=name]').set value
          when :start_date
            find('input[name=start_date]').set value
          when :effective_date
            find('input[name=effective_date]').set value
          else
            raise NotImplementedError
          end
        end
      end
    end

    def save_story_from_edit_mode(story)
      save_proc = -> do
        find('input[name=subject]').native.send_key :return

        expect(page)
          .not_to have_selector('input[name=subject]')
      end

      if story
        within_story(story, &save_proc)
      else
        save_proc.call
      end
    end

    def save_backlog_from_edit_mode(backlog)
      within_backlog(backlog) do
        find('input[name=name]').native.send_key :return

        expect(page)
          .to have_selector('.start_date.editable')
      end
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
      within('.story.editing') do
        alter_attributes_in_edit_story_mode(nil, attributes)

        save_story_from_edit_mode(nil)
      end
    end

    def click_in_backlog_menu(backlog, item_name)
      within_backlog(backlog) do
        find('.header .menu-trigger').click
        find('.header .menu .item', text: item_name).click
      end
    end

    def drag_in_sprint(moved, target, before: true)
      moved_element = find(story_selector(moved))
      target_element = find(story_selector(target))

      page
        .driver
        .browser
        .action
        .move_to(moved_element.native)
        .click_and_hold(moved_element.native)
        .perform

      page
        .driver
        .browser
        .action
        .move_to(target_element.native, 0, before ? +10 : +20)
        .release
        .perform
    end

    def fold_backlog(backlog)
      within_backlog(backlog) do
        find('.toggler').click
      end
    end

    def expect_sprint(sprint)
      expect(page)
        .to have_selector("#sprint_backlogs_container #{backlog_selector(sprint)}")
    end

    def expect_backlog(sprint)
      expect(page)
        .to have_selector("#owner_backlogs_container #{backlog_selector(sprint)}")
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
          .not_to have_selector(story_selector(story).to_s)
      end
    end

    def expect_for_story(story, attributes)
      within_story(story) do
        attributes.each do |key, value|
          case key
          when :subject
            expect(page)
              .to have_selector('div.subject', text: value)
          when :status
            expect(page)
              .to have_selector('div.status_id', text: value)
          when :type
            expect(page)
              .to have_selector('div.type_id', text: value)
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
        expect(all('.status_id option').map { |n| n.text.strip })
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
        existing_ids_in_order = all(ids.map { |id| "##{id}" }.join(', ')).map { |element| element[:id] }

        expect(existing_ids_in_order)
          .to eql(ids)
      end
    end

    def expect_in_backlog_menu(backlog, item_name)
      within_backlog(backlog) do
        find('.header .menu-trigger').click

        expect(page)
          .to have_selector('.header .menu .item', text: item_name)

        # Close it again for next test
        find('.header .menu-trigger').click
      end
    end

    def expect_and_dismiss_error(message)
      within '.ui-dialog' do
        expect(page)
          .to have_content message

        click_button('OK')
      end
    end

    def path
      backlogs_project_backlogs_path(project)
    end

    private

    def within_story(story, &block)
      within(story_selector(story), &block)
    end

    def within_backlog(backlog, &block)
      within(backlog_selector(backlog), &block)
    end

    def backlog_selector(backlog)
      "#backlog_#{backlog.id}"
    end

    def story_selector(story)
      "#story_#{story.id}"
    end

    def notification_type
      :ruby
    end
  end
end
