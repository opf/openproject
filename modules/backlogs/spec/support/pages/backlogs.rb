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

    def alter_attributes_in_edit_mode(story, attributes)
      within_story(story) do
        attributes.each do |key, value|
          case key
          when :subject
            fill_in 'subject', with: value
          when :story_points
            fill_in 'story points', with: value
          when :status
            select value, from: 'status'
          else
            raise NotImplementedError
          end
        end
      end
    end

    def save_story_from_edit_mode(story)
      within_story(story) do
        find('input[name=subject]').native.send_key :return

        expect(page)
          .not_to have_selector('input[name=subject]')
      end

      expect(page)
        .not_to have_selector("#{story_selector(story)}.ajax_indicator")
    end

    def edit_story(story, attributes)
      enter_edit_story_mode(story)

      alter_attributes_in_edit_mode(story, attributes)

      save_story_from_edit_mode(story)
    end

    def expect_story_in_sprint(story, sprint)
      expect(page)
        .to have_selector("#backlog_#{sprint.id} #{story_selector(story)}")
    end

    def expect_story_not_in_sprint(story, sprint)
      expect(page)
        .not_to have_selector("#backlog_#{sprint.id} #{story_selector(story)}")
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
        expect(all('.status_id option').map { |n| n.text.strip } )
          .to match_array(statuses.map(&:name))
      end
    end

    def expect_velocity(backlog, velocity)
      expect(page)
        .to have_selector("#backlog_#{backlog.id} .velocity", text: velocity.to_s)
    end

    def path
      backlogs_project_backlogs_path(project)
    end

    private

    def within_story(story, &block)
      within(story_selector(story), &block)
    end

    def story_selector(story)
      "#story_#{story.id}"
    end
  end
end
