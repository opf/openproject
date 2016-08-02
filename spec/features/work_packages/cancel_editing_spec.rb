# -- copyright
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
# ++

require 'spec_helper'

describe 'Cancel editing work package', js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:wp_page) { ::Pages::AbstractWorkPackage.new(work_package) }
  let(:paths) {
    [
      new_work_packages_path,
      new_split_work_packages_path,
      new_project_work_packages_path(project),
      new_split_project_work_packages_path(project)
    ]
  }

  before do
    work_package
    login_as(user)
  end

  def expect_active_edit(path)
    visit path
    loading_indicator_saveguard
    expect(page).to have_selector('.wp-edit-field.subject.-active')
  end

  def expect_subject(val)
    subject = page.find('#wp-new-inline-edit--field-subject')
    expect(subject.value).to eq(val)
  end

  it 'shows an alert when moving to other pages' do
    paths.each do |path|
      expect_active_edit(path)
      find('.home-link').click

      page.driver.browser.switch_to.alert.accept
      expect(page).to have_selector('h2', text: 'OpenProject')
    end
  end

  it 'cancels the editing when clicking the button' do
    paths.each do |path|
      expect_active_edit(path)
      find('#work-packages--edit-actions-cancel').click

      expect(wp_page).not_to have_alert_dialog
    end
  end

  it 'allows to move from split to full screen in edit mode' do
    # Start creating on split view
    expect_active_edit(new_split_work_packages_path)

    find('#wp-new-inline-edit--field-subject').set 'foobar'

    # Expect editing works when moving to full screen
    find('#work-packages-show-view-button').click

    expect(wp_page).not_to have_alert_dialog
    expect(page).to have_selector('.wp-edit-field.subject.-active')
    expect_subject('foobar')

    # Moving back also works
    page.evaluate_script('window.history.back()')

    expect(wp_page).not_to have_alert_dialog
    expect(page).to have_selector('.wp-edit-field.subject.-active')
    expect_subject('foobar')

    # Cancel edition
    find('#work-packages--edit-actions-cancel').click
    expect(wp_page).not_to have_alert_dialog

    # Visiting another page does not create alert
    find('.home-link').click
    expect(wp_page).not_to have_alert_dialog
  end
end
