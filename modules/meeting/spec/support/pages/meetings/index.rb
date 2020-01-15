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

require_relative './new'

module Pages::Meetings
  class Index < Pages::Page
    attr_accessor :project

    def initialize(project)
      self.project = project
    end

    def click_create_new
      within '.toolbar-items' do
        click_link 'Meeting'
      end

      New.new(project)
    end

    def expect_no_create_new_button
      within '.toolbar-items' do
        expect(page)
          .to have_no_link 'Meeting'
      end
    end

    def expect_no_meetings_listed
      within '#content-wrapper' do
        expect(page)
          .to have_content I18n.t(:no_results_title_text)
      end
    end

    def expect_meetings_listed(*meetings)
      within '#content-wrapper' do
        meetings.each do |meeting|
          expect(page).to have_selector(".meeting",
                                        text: meeting.title)
        end
      end
    end

    def expect_meetings_not_listed(*meetings)
      within '#content-wrapper' do
        meetings.each do |meeting|
          expect(page).to have_no_selector(".meeting",
                                           text: meeting.title)
        end
      end
    end

    def expect_to_be_on_page(number)
      expect(page)
        .to have_selector('.pagination--item.-current',
                          text: number)
    end

    def to_page(number)
      within '.pagination--pages' do
        click_link number.to_s
      end
    end

    def to_today
      click_link 'today'
    end

    def navigate_by_menu
      visit project_path(project)
      within '#main-menu' do
        click_link 'Meetings'
      end
    end

    def path
      meetings_path(project)
    end
  end
end
