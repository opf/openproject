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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Projects module administration" do
  let!(:project) do
    create(:project, enabled_module_names: [])
  end

  let(:permissions) { %i(edit_project select_project_modules view_work_packages) }
  let(:settings_page) { Pages::Projects::Settings.new(project) }

  current_user do
    create(:user, member_with_permissions: { project => permissions })
  end

  it "allows adding and removing modules" do
    project_work_packages_menu_link_selector = '//ul[contains(@class, "menu_root")]//span[text()="Work packages"]'

    settings_page.visit_tab!("modules")

    expect(page).to have_unchecked_field "Activity"
    expect(page).to have_unchecked_field "Calendar"
    expect(page).to have_unchecked_field "Time and costs"
    expect(page).to have_unchecked_field "Work packages"

    expect(page).to have_no_xpath(project_work_packages_menu_link_selector)

    check "Activity"
    click_button "Save"

    settings_page.expect_toast message: I18n.t(:notice_successful_update)

    expect(page).to have_checked_field "Activity"
    expect(page).to have_unchecked_field "Calendar"
    expect(page).to have_unchecked_field "Time and costs"
    expect(page).to have_unchecked_field "Work packages"

    check "Calendar"
    click_button "Save"

    expect(page)
      .to have_css ".op-toast.-error",
                   text: I18n.t(:"activerecord.errors.models.project.attributes.enabled_modules.dependency_missing",
                                dependency: "Work packages",
                                module: "Calendars")

    expect(page).to have_no_xpath(project_work_packages_menu_link_selector)

    check "Work packages"
    click_button "Save"

    settings_page.expect_toast message: I18n.t(:notice_successful_update)

    expect(page).to have_checked_field "Activity"
    expect(page).to have_checked_field "Calendars"
    expect(page).to have_unchecked_field "Time and costs"
    expect(page).to have_checked_field "Work packages"

    expect(page).to have_xpath(project_work_packages_menu_link_selector, visible: :all)

    uncheck "Work packages"
    click_button "Save"

    expect(page).to have_no_xpath(project_work_packages_menu_link_selector)
  end

  context "with a user who does not have the correct permissions (#38097)" do
    let(:user_without_permission) do
      create(:user,
             member_with_permissions: { project => %i(edit_project) })
    end

    before do
      login_as user_without_permission
      settings_page.visit_tab!("general")
    end

    it "I can't see the modules menu item" do
      expect(page).to have_no_css('[data-name="settings_modules"]')
    end
  end
end
