# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# ++

require 'spec_helper'

describe 'Cancel editing work package', js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:work_package2) { FactoryBot.create(:work_package, project: project) }
  let(:wp_page) { ::Pages::AbstractWorkPackage.new(work_package) }
  let(:wp_table) { ::Pages::WorkPackagesTable.new }
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
    work_package2
    login_as(user)
  end

  def expect_active_edit(path)
    visit path
    expect_angular_frontend_initialized
    expect(page).to have_selector('#wp-new-inline-edit--field-subject', wait: 10)
  end

  def expect_subject(val)
    subject = page.find('#wp-new-inline-edit--field-subject')
    expect(subject.value).to eq(val)
  end

  def move_to_home_page(alert: true)
    find('.home-link').click

    page.driver.browser.switch_to.alert.accept if alert
    expect(page).to have_selector('#projects-menu', text: 'Select a project')
  end

  it 'does not show an alert when moving to other pages' do
    # This used to show an alert until browsers dropped support
    # for `onbeforeunload`.
    #
    # We want to find a way how to to regain that possibility
    # at some later point in time. Until then we keep that block
    # and only flip
    #   move_to_home_page(alert: true)
    # to
    #  move_to_home_page(alert: false)
    paths.each do |path|
      expect_active_edit(path)
      move_to_home_page(alert: false)
    end
  end

  it 'shows an alert when moving to other states' do
    expect_active_edit(new_split_work_packages_path)
    loading_indicator_saveguard
    wp_table.expect_work_package_listed(work_package2)

    wp_table.open_split_view(work_package2)
    page.driver.browser.switch_to.alert.dismiss

    expect(page).to have_selector('#wp-new-inline-edit--field-subject')
    expect(wp_page).not_to have_alert_dialog
  end

  it 'shows an alert when moving to other states while editing a single attribute (Regression #25135)' do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package, work_package2)

    # Edit subject in split page
    split_page = wp_table.open_split_view(work_package)
    version = split_page.edit_field :version
    version.activate!

    # Decline move, expect field still active
    wp_table.open_split_view(work_package2)
    page.driver.browser.switch_to.alert.dismiss
    version.expect_active!

    sleep 1

    # Now accept to move to the second page
    split_page = wp_table.open_split_view(work_package2)
    page.driver.browser.switch_to.alert.accept
    version = split_page.edit_field :version
    version.expect_inactive!
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
    find('.work-packages-show-view-button').click

    expect(wp_page).not_to have_alert_dialog
    expect(page).to have_selector('#wp-new-inline-edit--field-subject')
    expect_subject('foobar')

    # Moving back also works
    page.execute_script('window.history.back()')

    expect(wp_page).not_to have_alert_dialog
    expect(page).to have_selector('#wp-new-inline-edit--field-subject')
    expect_subject('foobar')

    # Cancel edition
    find('#work-packages--edit-actions-cancel').click
    expect(wp_page).not_to have_alert_dialog

    # Visiting another page does not create alert
    find('.home-link').click
    expect(wp_page).not_to have_alert_dialog
  end

  it 'correctly cancels setting the back route (Regression #30714)' do
    wp_page = ::Pages::FullWorkPackage.new work_package
    wp_page.visit!
    wp_page.ensure_page_loaded

    # Edit description in full view
    description = wp_page.edit_field :description
    description.activate!
    description.click_and_type_slowly 'foobar'

    # Try to move back to list, expect warning
    wp_page.go_back
    wp_page.dismiss_alert_dialog!

    # Now cancel the field
    description.cancel_by_click

    # Now we should be able to get back to list
    wp_page.go_back

    wp_table.expect_work_package_listed(work_package, work_package2)
  end

  context 'when user does not want to be warned' do
    before do
      FactoryBot.create(:user_preference, user: user, others: { warn_on_leaving_unsaved: false })
    end

    it 'does not alert when moving anywhere' do
      # Moving to angular states
      expect_active_edit(new_split_work_packages_path)
      wp_table.expect_work_package_listed(work_package2)

      wp_table.open_split_view(work_package2)
      expect(wp_page).not_to have_alert_dialog

      expect(page).to have_no_selector('#wp-new-inline-edit--field-subject')
      expect(page).to have_selector('.work-packages--details--subject', text: work_package2.subject)

      # Moving somewhere else
      expect_active_edit(new_split_work_packages_path)
      move_to_home_page(alert: false)
    end
  end
end
