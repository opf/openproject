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

feature 'Work packages top menu items', js: true, selenium: true do
  include WorkPackagesFilterHelper
  let(:user) { FactoryGirl.create :user }

  let(:new_wp_item) { I18n.t('label_work_package_new') }
  let(:all_wp_item) { I18n.t('label_all') }
  let(:assigned_wp_item) { I18n.t('label_assigned_to_me') }
  let(:reported_wp_item) { I18n.t('label_reported_by_me') }
  let(:responsible_wp_item) { I18n.t('label_responsible_for') }
  let(:watched_wp_item) { I18n.t('label_watched_by_me') }

  let(:all_items) {
    [new_wp_item, all_wp_item, assigned_wp_item,
     reported_wp_item, responsible_wp_item, watched_wp_item]
  }

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
  end

  context 'as an admin' do
    let(:work_packages) { find(:css, '#work-packages-menu') }
    let(:user) { FactoryGirl.create :admin }
    before do
      work_packages.click
    end

    it 'displays all items' do
      has_menu_items(new_wp_item,
                     all_wp_item,
                     assigned_wp_item,
                     reported_wp_item,
                     responsible_wp_item,
                     watched_wp_item)
    end

    it 'visits the new work package page' do
      expect(page).to have_content(new_wp_item)
      click_link new_wp_item
      expect(page).to have_current_path(new_work_packages_path)
    end

    it 'visits the all work packages page' do
      expect(page).to have_content(all_wp_item)
      click_link all_wp_item
      expect(page).to have_current_path(index_work_packages_path)
    end

    it 'visits the work packages assigned to me page' do
      expect(page).to have_content(assigned_wp_item)
      click_link assigned_wp_item
      expect(page).to have_current_path(work_packages_assigned_to_me_path)
    end

    it 'visits the work packages reported by me page' do
      expect(page).to have_content(reported_wp_item)
      click_link reported_wp_item
      expect(page).to have_current_path(work_packages_reported_by_me_path)
    end

    it 'visits the work packages I am responsible for page' do
      expect(page).to have_content(responsible_wp_item)
      click_link responsible_wp_item
      expect(page).to have_current_path(work_packages_responsible_for_path)
    end

    it 'visits the work packages watched by me page' do
      expect(page).to have_content(watched_wp_item)
      click_link watched_wp_item
      expect(page).to have_current_path(work_packages_watched_path)
    end
  end

  context 'as a user with permissions', allowed_to: true do
    let(:work_packages) { find(:css, '#work-packages-menu') }
    before do
      work_packages.click
    end

    it 'displays all options' do
      has_menu_items(new_wp_item,
                     all_wp_item,
                     assigned_wp_item,
                     reported_wp_item,
                     responsible_wp_item,
                     watched_wp_item)
    end
  end

  context 'as a user without any permission', allowed_to: false do
    it 'shows no top menu entry Work packages' do
      has_menu_items
      expect(page).not_to have_css('#work-packages-menu')
    end
  end

  context 'as an anonymous user' do
    let(:user) { FactoryGirl.create :anonymous }
    let(:work_packages) { find(:css, '#work-packages-menu') }
    before do
      work_packages.click
    end

    it 'displays only add new work package' do
      has_menu_items(new_wp_item, all_wp_item)
    end
  end
end
