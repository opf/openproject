# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Projects module administration" do
  let!(:project) do
    create(:project, enabled_module_names: [])
  end

  let(:permissions) { %i(edit_project select_project_modules view_work_packages manage_types manage_categories) }
  let(:modules_settings_page) { Pages::Projects::Settings::Modules.new(project) }
  let(:work_packages_settings_page) { Pages::Projects::Settings::WorkPackages.new(project) }

  current_user do
    create(:user, member_with_permissions: { project => permissions })
  end

  it "allows adding and removing modules" do
    project_work_packages_tab_selector = '//ul[contains(@class, "tabnav-tabs")]//span[text()="Categories"]'

    modules_settings_page.visit!

    expect(page).to have_unchecked_field "Activity"
    expect(page).to have_unchecked_field "Calendar"
    expect(page).to have_unchecked_field "Time and costs"
    expect(page).to have_unchecked_field "Work packages"

    work_packages_settings_page.visit!
    expect(page).to have_no_xpath(project_work_packages_tab_selector)
    modules_settings_page.visit!

    check "Activity"
    click_button "Save"

    expect_flash type: :success, message: I18n.t(:notice_successful_update)

    expect(page).to have_checked_field "Activity"
    expect(page).to have_unchecked_field "Calendar"
    expect(page).to have_unchecked_field "Time and costs"
    expect(page).to have_unchecked_field "Work packages"

    check "Calendar"
    click_button "Save"

    expect_flash(type: :error, message:
      I18n.t(:"activerecord.errors.models.project.attributes.enabled_modules.dependency_missing",
             dependency: "Work packages",
             module: "Calendars"))

    work_packages_settings_page.visit!
    expect(page).to have_no_xpath(project_work_packages_tab_selector)
    modules_settings_page.visit!

    check "Calendar"
    check "Work packages"
    click_button "Save"

    expect_flash type: :success, message: I18n.t(:notice_successful_update)

    expect(page).to have_checked_field "Activity"
    expect(page).to have_checked_field "Calendars"
    expect(page).to have_unchecked_field "Time and costs"
    expect(page).to have_checked_field "Work packages"

    work_packages_settings_page.visit!
    expect(page).to have_xpath(project_work_packages_tab_selector, visible: :all)
    modules_settings_page.visit!

    uncheck "Work packages"
    click_button "Save"

    work_packages_settings_page.visit!
    expect(page).to have_xpath(project_work_packages_tab_selector)
  end

  context "with a user who does not have the correct permissions (#38097)" do
    let(:user_without_permission) do
      create(:user,
             member_with_permissions: { project => %i(edit_project) })
    end
    let(:general_settings_page) { Pages::Projects::Settings::General.new(project) }

    before do
      login_as user_without_permission
      general_settings_page.visit!
    end

    it "I can't see the modules menu item" do
      expect(page).to have_no_css('[data-name="settings_modules"]')
    end
  end
end
