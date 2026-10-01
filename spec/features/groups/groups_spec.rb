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

RSpec.describe "group memberships through groups page", :js do
  shared_let(:admin) { create(:admin) }
  let!(:group) { create(:group, lastname: "Bob's Team") }

  let(:groups_page) { Pages::Groups.new }

  context "as an admin" do
    before do
      allow(User).to receive(:current).and_return admin
    end

    it "I can see groups" do
      groups_page.visit!
      expect(groups_page).to have_group "Bob's Team"

      click_on "Bob's Team"

      expect(page).to have_current_path(edit_group_path(group))
    end

    context "with a custom field" do
      let!(:custom_field) do
        create(:group_custom_field, :string,
               name: "Department",
               is_required: true)
      end

      it "I can create a group with a custom field value including validation" do
        groups_page.visit!

        click_on "Group"

        expect(page).to have_text("New group")

        fill_in "Name", with: "Development Team"

        # Intentionally not filling in the required custom field
        click_on "Create"

        # Should stay on the form page and show validation error
        expect(page).to have_text("New group")
        expect(page).to have_field(custom_field.name, with: "", validation_error: "Value can't be blank.")

        fill_in custom_field.name, with: "Engineering"

        click_on "Create"

        expect_flash(type: :notice, message: I18n.t(:notice_successful_create))
        expect(groups_page).to have_group "Development Team"

        # Verify the custom field value was saved
        created_group = Group.find_by(lastname: "Development Team")
        expect(created_group).not_to be_nil
        expect(created_group.typed_custom_value_for(custom_field)).to eq("Engineering")
      end

      it "I can update a group with a custom field value including validation" do
        # Create a group with initial custom field value
        create(:group, lastname: "Marketing Team", custom_field_values: { custom_field.id => "Sales" })

        groups_page.visit!
        groups_page.edit_group! "Marketing Team"

        expect(page).to have_text("Marketing Team")

        # Update the group name and clear the required custom field
        fill_in "Name", with: "Updated Marketing Team"
        fill_in custom_field.name, with: ""

        click_on "Save"

        # Should stay on the form page and show validation error
        expect(page).to have_field("Name", with: "Updated Marketing Team")
        expect(page).to have_field(custom_field.name, with: "", validation_error: "Value can't be blank.")

        # Now provide a valid value
        fill_in custom_field.name, with: "Marketing & Sales"

        click_on "Save"

        expect_flash(type: :notice, message: I18n.t(:notice_successful_update))
        expect(groups_page).to have_group "Updated Marketing Team"

        # Verify the custom field value was updated
        updated_group = Group.find_by(lastname: "Updated Marketing Team")
        expect(updated_group).not_to be_nil
        expect(updated_group.typed_custom_value_for(custom_field)).to eq("Marketing & Sales")
      end
    end
  end
end
