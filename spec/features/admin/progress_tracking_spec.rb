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

RSpec.describe "Progress tracking admin page", :js, :with_cuprite do
  include ActionView::Helpers::SanitizeHelper
  include Toasts::Expectations

  shared_let(:admin) { create(:admin) }
  current_user { admin }

  it "displays a warning when changing progress calculation mode" do
    Setting.work_package_done_ratio = "field"
    visit admin_settings_progress_tracking_path

    # change from work-based to status-based
    expect(page).to have_field("Work-based", checked: true)
    expect(page).to have_field("Status-based", checked: false)

    find(:radio_button, "Status-based").click

    expected_warning_text =
      I18n.t("js.admin.work_packages_settings.warning_progress_calculation_mode_change_from_field_to_status_html")
    expected_warning_text = strip_tags(expected_warning_text)[..80] # take only the beginning of the text
    expect(page).to have_text(expected_warning_text)

    click_on "Save"
    expect_and_dismiss_flash(message: "Successful update.")
    expect(Setting.find_by(name: "work_package_done_ratio").value).to eq("status")

    # now change from status-based to work-based
    expect(page).to have_field("Work-based", checked: false)
    expect(page).to have_field("Status-based", checked: true)

    find(:radio_button, "Work-based").click
    expected_warning_text =
      I18n.t("js.admin.work_packages_settings.warning_progress_calculation_mode_change_from_status_to_field_html")
    expected_warning_text = strip_tags(expected_warning_text)[..80] # take only the beginning of the text
    expect(page).to have_text(expected_warning_text)

    click_on "Save"
    expect_and_dismiss_flash(message: "Successful update.")
    expect(Setting.find_by(name: "work_package_done_ratio").value).to eq("field")
  end

  it "disables the status closed radio button when changing to status-based" do
    Setting.work_package_done_ratio = "field"
    visit admin_settings_progress_tracking_path
    expect(page).to have_field("No change", disabled: false)
    expect(page).to have_field("Automatically set to 100%", disabled: false)

    find(:radio_button, "Status-based").click
    expect(page).to have_field("No change", disabled: true)
    expect(page).to have_field("Automatically set to 100%", disabled: true)

    find(:radio_button, "Work-based").click
    expect(page).to have_field("No change", disabled: false)
    expect(page).to have_field("Automatically set to 100%", disabled: false)

    Setting.work_package_done_ratio = "status"
    visit admin_settings_progress_tracking_path
    expect(page).to have_field("No change", disabled: true)
    expect(page).to have_field("Automatically set to 100%", disabled: true)
  end
end
