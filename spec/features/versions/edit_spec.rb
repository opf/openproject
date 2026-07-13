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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "version edit", :js do
  let(:project) { create(:project, enabled_module_names: %w[backlogs work_package_tracking]) }
  let(:version) { create(:version, project:, sharing: "descendants") }
  let(:new_version_name) { "A new version name" }
  let(:permissions) { { project => %i[manage_versions view_work_packages] } }
  let(:user) { create(:user, member_with_permissions: permissions) }

  before do
    login_as(user)
  end

  it "edit a version" do
    # from the version show page
    visit version_path(version)

    page.find_test_selector("version-edit-button").click

    fill_in "Name", with: new_version_name

    click_button "Save"

    expect(page)
      .to have_current_path(version_path(version))
    expect(page)
      .to have_content new_version_name
  end

  context "with a custom field" do
    let!(:custom_field) do
      create(:version_custom_field, :string,
             name: "Release Notes",
             is_required: true)
    end

    it "I can update a version with a custom field value including validation" do
      # Create a version with initial custom field value
      version = create(:version,
                       name: "Version 2.0",
                       project: project,
                       custom_field_values: { custom_field.id => "Initial release notes" })

      visit edit_version_path(version)

      expect(page).to have_text("Version 2.0")

      # Update the version name and clear the required custom field
      fill_in "Name", with: "Version 2.1"
      fill_in custom_field.name, with: ""

      click_on "Save"

      # Should stay on the form page and show validation error
      expect(page).to have_text("Version 2.1")
      expect(page).to have_field(custom_field.name, with: "", validation_error: "Value can't be blank")

      # Now provide a valid value
      fill_in custom_field.name, with: "Security updates and bug fixes"

      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_content("Version 2.1")

      # Verify the custom field value was updated
      updated_version = Version.find_by(name: "Version 2.1")
      expect(updated_version).not_to be_nil
      expect(updated_version.send(:"custom_field_#{custom_field.id}"))
        .to eq("Security updates and bug fixes")
    end
  end
end
