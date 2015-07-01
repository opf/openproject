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

feature 'Top menu items', js: true do
  let(:user) { FactoryGirl.create :user }
  let(:modules) { find(:css, "[title=#{I18n.t('label_modules')}]") }

  let(:news_item) { I18n.t('label_news_plural') }
  let(:work_packages_item) { I18n.t('label_work_package_plural') }
  let(:time_entries_item) { I18n.t('label_time_sheet_menu') }

  let(:all_items) { [news_item, work_packages_item, time_entries_item] }

  def has_menu_items(*labels)
    labels.each do |l|
      expect(page).to have_link(l)
    end
    (all_items - labels).each do |l|
      expect(page).not_to have_link(l)
    end
  end

  before do |ex|
    allow(User).to receive(:current).and_return user

    if ex.metadata.key?(:allowed_to)
      allow(user).to receive(:allowed_to?).and_return(ex.metadata[:allowed_to])
    end

    visit root_path
    modules.click
  end

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
