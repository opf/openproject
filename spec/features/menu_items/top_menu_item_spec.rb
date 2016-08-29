#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

feature 'Top menu items', js: true, selenium: true do
  let(:user) { FactoryGirl.create :user }
  let(:open_menu) { true }

  def has_menu_items(*labels)

    within '#top-menu' do
      labels.each do |l|
        expect(page).to have_link(l)
      end
      (all_items - labels).each do |l|
        expect(page).not_to have_link(l)
      end
    end
  end

  before do |ex|
    allow(User).to receive(:current).and_return user

    if ex.metadata.key?(:allowed_to)
      allow(user).to receive(:allowed_to?).and_return(ex.metadata[:allowed_to])
    end

    visit root_path
    top_menu.click if open_menu
  end

  describe 'Modules' do
    let(:top_menu) { find(:css, "[title=#{I18n.t('label_modules')}]") }

    let(:news_item) { I18n.t('label_news_plural') }
    let(:work_packages_item) { I18n.t('label_work_package_plural') }
    let(:time_entries_item) { I18n.t('label_time_sheet_menu') }

    let(:all_items) { [news_item, work_packages_item, time_entries_item] }

    context 'as an admin' do
      let(:user) { FactoryGirl.create :admin }
      it 'displays all items' do
        has_menu_items(work_packages_item, time_entries_item, news_item)
      end

      it 'visits the work package page' do
        click_link work_packages_item
        expect(current_path).to eq(work_packages_path)
      end

      it 'visits the time sheet page' do
        click_link time_entries_item
        expect(current_path).to eq(time_entries_path)
      end

      it 'visits the work package page' do
        click_link news_item
        expect(current_path).to eq(news_index_path)
      end
    end

    context 'as a regular user' do
      it 'displays news only' do
        has_menu_items news_item
      end
    end

    context 'as a user with permissions', allowed_to: true do
      it 'displays all options' do
        has_menu_items(work_packages_item, time_entries_item, news_item)
      end
    end

    context 'as an anonymous user' do
      let(:user) { FactoryGirl.create :anonymous }
      it 'displays only news' do
        has_menu_items news_item
      end
    end
  end

  describe 'Projects' do
    let(:top_menu) { find(:css, '#projects-menu') }

    let(:new_project) { I18n.t(:label_project_new) }
    let(:all_projects) { I18n.t(:label_project_view_all) }
    let(:all_items) { [new_project, all_projects] }

    context 'as an admin' do
      let(:user) { FactoryGirl.create :admin }
      it 'displays all items' do
        has_menu_items(new_project, all_projects)
      end

      it 'visits the work package page' do
        within '.drop-down--projects' do
          click_link new_project
        end

        expect(current_path).to eq(new_project_path)
      end

      it 'visits the time sheet page' do
        within '.drop-down--projects' do
          click_link all_projects
        end
        expect(current_path).to eq(projects_path)
      end
    end

    context 'as a user without project permission' do
      before do
        Role.non_member.update_attribute :permissions, [:view_project]
      end
      it 'does not display new_project' do
        has_menu_items all_projects
      end
    end

    context 'as an anonymous user' do
      let(:user) { FactoryGirl.create :anonymous }
      let(:open_menu) { false }

      it 'does not show the menu' do
        expect(page).to have_no_selector('#projects-menu')
      end
    end
  end
end
