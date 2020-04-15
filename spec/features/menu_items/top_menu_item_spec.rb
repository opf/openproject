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

require 'spec_helper'

feature 'Top menu items', js: true, selenium: true do
  let(:user) { FactoryBot.create :user }
  let(:open_menu) { true }

  def has_menu_items?(*labels)
    within '#top-menu' do
      labels.each do |l|
        expect(page).to have_link(l)
      end
      (all_items - labels).each do |l|
        expect(page).not_to have_link(l)
      end
    end
  end

  def click_link_in_open_menu(title)
    # if the menu is not completely expanded (e.g. if the frontend thread is too fast),
    # the click might be ignored

    within '.drop-down.open ul[aria-expanded=true]' do
      expect(page).not_to have_selector('[style~=overflow]')

      page.find_link(title).find('span').click
    end
  end

  before do |ex|
    allow(User).to receive(:current).and_return user
    FactoryBot.create(:anonymous_role)
    FactoryBot.create(:non_member)

    if ex.metadata.key?(:allowed_to)
      allow(user).to receive(:allowed_to?).and_return(ex.metadata[:allowed_to])
    end

    visit root_path
    top_menu.click if open_menu
  end

  describe 'Modules' do
    !let(:top_menu) { find(:css, "[title=#{I18n.t('label_modules')}]") }

    let(:news_item) { I18n.t('label_news_plural') }
    let(:time_entries_item) { I18n.t('label_time_sheet_menu') }
    let(:reporting_item) { I18n.t('cost_reports_title') }

    let(:all_items) { [news_item, time_entries_item] }

    context 'as an admin' do
      let(:user) { FactoryBot.create :admin }
      it 'displays all items' do
        has_menu_items?(reporting_item, news_item)
      end

      it 'visits the news page' do
        click_link_in_open_menu(news_item)
        expect(page).to have_current_path(news_index_path)
      end
    end

    context 'as a regular user' do
      it 'displays news only' do
        has_menu_items? news_item
      end
    end

    context 'as a user with permissions', allowed_to: true do
      it 'displays all options' do
        has_menu_items?(reporting_item, news_item)
      end
    end

    context 'as a user without permissions', allowed_to: false do
      let(:open_menu) { false }
      it 'displays no options and hides the module menu' do
        has_menu_items?
        expect(page).not_to have_link('Modules')
      end
    end

    context 'as an anonymous user' do
      let(:user) { FactoryBot.create :anonymous }
      it 'displays only news' do
        has_menu_items? news_item
      end
    end
  end

  describe 'Projects' do
    let(:top_menu) { find(:css, '#projects-menu') }

    let(:new_project) { I18n.t(:label_project_new) }
    let(:all_projects) { I18n.t(:label_project_view_all) }
    let(:all_items) { [new_project, all_projects] }

    context 'as an admin' do
      let(:user) { FactoryBot.create :admin }
      it 'displays all items' do
        has_menu_items?(new_project, all_projects)
      end

      it 'visits the work package page' do
        click_link_in_open_menu(new_project)

        expect(page).to have_current_path(new_project_path)
      end

      it 'visits the projects page' do
        click_link_in_open_menu(all_projects)

        expect(page).to have_current_path(projects_path)
      end
    end

    context 'as a user without project permission' do
      before do
        Role.non_member.update_attribute :permissions, [:view_project]
      end
      it 'does not display new_project' do
        has_menu_items? all_projects
      end
    end

    context 'as an anonymous user' do
      let(:user) { FactoryBot.create :anonymous }
      let(:open_menu) { false }

      it 'does not show the menu' do
        expect(page).to have_no_selector('#projects-menu')
      end
    end
  end
end
