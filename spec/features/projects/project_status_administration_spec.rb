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

RSpec.describe "Projects status administration", :js, :with_cuprite do
  include_context "ng-select-autocomplete helpers"

  let(:current_user) do
    create(:user) do |u|
      create(:global_member,
             principal: u,
             roles: [create(:global_role, permissions: global_permissions)])
    end
  end
  let(:global_permissions) { [:add_project] }
  let(:project_permissions) { [:edit_project] }
  let!(:project_role) do
    create(:project_role, permissions: project_permissions) do |r|
      allow(Setting)
        .to receive(:new_project_user_role_id)
        .and_return(r.id.to_s)
    end
  end
  let(:status_description) { Components::WysiwygEditor.new('[data-qa-field-name="statusExplanation"]') }

  let(:name_field) { FormFields::InputFormField.new :name }
  let(:status_field) { FormFields::SelectFormField.new :status }

  before do
    login_as current_user
  end

  it "allows setting the status on project creation" do
    visit new_project_path

    # Create the project with status
    click_button "Advanced settings"

    name_field.set_value "New project"
    status_field.select_option "On track"

    status_description.set_markdown "Everything is fine at the start"
    status_description.expect_supports_macros

    click_button "Save"

    expect(page).to have_current_path /projects\/new-project\/?/

    # Check that the status has been set correctly
    visit project_settings_general_path(project_id: "new-project")

    status_field.expect_selected "ON TRACK"
    status_description.expect_value "Everything is fine at the start"

    status_field.select_option "Off track"
    status_description.set_markdown "Oh no"

    click_button "Save"

    status_field.expect_selected "OFF TRACK"
    status_description.expect_value "Oh no"
  end
end
