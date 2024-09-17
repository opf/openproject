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

RSpec.describe "Invite user modal custom fields", :js, :with_cuprite do
  shared_let(:project) { create(:project) }

  let(:permissions) { %i[view_project manage_members] }
  let(:global_permissions) { %i[create_user manage_user] } # TODO: Figure out why create_user is not enough here
  let(:principal) { build(:invited_user) }
  let(:modal) do
    Components::Users::InviteUserModal.new project:,
                                           principal:,
                                           role:
  end
  let!(:role) do
    create(:project_role,
           name: "Member",
           permissions:)
  end

  let!(:boolean_cf) { create(:user_custom_field, :boolean, name: "bool", is_required: true) }
  let!(:integer_cf) { create(:user_custom_field, :integer, name: "int", is_required: true) }
  let!(:text_cf) { create(:user_custom_field, :text, name: "Text", is_required: true) }
  let!(:string_cf) { create(:user_custom_field, :string, name: "String", is_required: true) }
  # TODO float not supported yet
  # let!(:float_cf) { create :user_custom_field, :float, name: 'Float', is_required: true }
  let!(:list_cf) { create(:user_custom_field, :list, name: "List", is_required: true) }
  let!(:list_multi_cf) { create(:user_custom_field, :list, name: "Multi list", multi_value: true, is_required: true) }

  let!(:non_req_cf) { create(:user_custom_field, :string, name: "non req", is_required: false) }

  let(:boolean_field) { FormFields::InputFormField.new boolean_cf }
  let(:integer_field) { FormFields::InputFormField.new integer_cf }
  let(:text_field) { FormFields::EditorFormField.new text_cf }
  let(:string_field) { FormFields::InputFormField.new string_cf }
  # TODO float not supported yet
  # let(:float_field) { ::FormFields::InputFormField.new float_cf }
  let(:list_field) { FormFields::SelectFormField.new list_cf }
  let(:list_multi_field) { FormFields::SelectFormField.new list_multi_cf }

  let(:quick_add) { Components::QuickAddMenu.new }

  current_user do
    create(:user,
           :skip_validations,
           member_with_roles: { project => role },
           global_permissions:)
  end

  it "shows the required fields during the principal step" do
    retry_block do
      visit home_path

      quick_add.expect_visible

      quick_add.toggle

      wait_for_network_idle

      quick_add.click_link "Invite user"

      modal.project_step

      # Fill the principal and try to go to next
      modal.principal_step

      page.find("form.ng-invalid", wait: 10)
    end

    modal.within_modal do
      expect(page).to have_text "bool can't be blank."
      expect(page).to have_text "int can't be blank."
      expect(page).to have_text "Text can't be blank."
      expect(page).to have_text "String can't be blank."
      expect(page).to have_text "List can't be blank."
      expect(page).to have_text "Multi list can't be blank."

      # Does not show the non req field
      expect(page).to have_no_text non_req_cf.name
    end

    # Fill all fields
    boolean_field.input_element.check
    integer_field.set_value "1234"
    text_field.set_value "A **markdown** value"
    string_field.set_value "String value"

    list_field.select_option "A"
    list_multi_field.select_option "A", "B"

    modal.click_next

    # Remaining steps
    modal.expect_text "Invite user"
    modal.confirmation_step
    modal.click_modal_button "Send invitation"

    # Close
    modal.expect_text "#{principal.mail} was invited!"
    modal.click_modal_button "Continue"

    # Expect to be added to project
    invited = project.users.last
    expect(invited.mail).to eq principal.mail

    expect(invited.custom_value_for(boolean_cf).typed_value).to be true
    expect(invited.custom_value_for(integer_cf).typed_value).to eq 1234
    expect(invited.custom_value_for(text_cf).typed_value).to eq "A **markdown** value"
    expect(invited.custom_value_for(string_cf).typed_value).to eq "String value"
    expect(invited.custom_value_for(list_cf).typed_value).to eq "A"
    expect(invited.custom_value_for(list_multi_cf).map(&:typed_value)).to eq %w[A B]
  end
end
