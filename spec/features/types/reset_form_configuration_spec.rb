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

RSpec.describe "Reset form configuration", :js do
  shared_let(:admin) { create(:admin) }
  let(:type) { create(:type) }

  let(:project) { create(:project, types: [type]) }
  let(:form) { Components::Admin::TypeConfigurationForm.new }
  let(:dialog) { Components::ConfirmationDialog.new }

  describe "with EE token and CFs", with_ee: %i[edit_attribute_groups] do
    let(:custom_fields) { [custom_field] }
    let(:custom_field) { create(:issue_custom_field, :integer, is_required: true, name: "MyNumber") }
    let(:cf_identifier) { custom_field.attribute_name }
    let(:cf_identifier_api) { cf_identifier.camelcase(:lower) }

    before do
      project
      custom_field

      login_as(admin)
      visit edit_type_tab_path(id: type.id, tab: "form_configuration")
    end

    it "resets the form properly after changes with CFs (Regression test #27487)" do
      # Should be initially disabled
      form.expect_inactive(cf_identifier)

      # Add into new group
      form.add_attribute_group("New Group")
      form.move_to(cf_identifier, "New Group")
      form.expect_attribute(key: cf_identifier)

      form.save_changes
      expect(page).to have_css(".op-toast.-success", text: "Successful update.", wait: 10)

      SeleniumHubWaiter.wait
      form.reset_button.click
      dialog.expect_open
      dialog.confirm

      # Wait for page reload
      SeleniumHubWaiter.wait

      expect(page).to have_no_css(".group-head", text: "NEW GROUP")
      expect(page).to have_no_css(".group-head", text: "OTHER")
      type.reload

      expect(type.custom_field_ids).to be_empty

      new_group = type.attribute_groups.detect { |g| g.key == "New Group" }
      expect(new_group).not_to be_present

      other_group = type.attribute_groups.detect { |g| g.key == :other }
      expect(other_group).not_to be_present
    end
  end
end
