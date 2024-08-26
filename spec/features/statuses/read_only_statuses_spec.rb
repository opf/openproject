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

RSpec.describe "Read-only statuses affect work package editing", :js, with_ee: %i[readonly_work_packages] do
  let(:locked_status) { create(:status, name: "Locked", is_readonly: true) }
  let(:unlocked_status) { create(:status, name: "Unlocked", is_readonly: false) }
  let(:cf_all) do
    create(:work_package_custom_field, is_for_all: true, field_format: "text")
  end

  let(:type) { create(:type_bug, custom_fields: [cf_all]) }
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           status: unlocked_status)
  end

  let(:role) { create(:project_role, permissions: %i[edit_work_packages view_work_packages]) }
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end

  let!(:workflow1) do
    create(:workflow,
           type_id: type.id,
           old_status: unlocked_status,
           new_status: locked_status,
           role:)
  end
  let!(:workflow2) do
    create(:workflow,
           type_id: type.id,
           old_status: locked_status,
           new_status: unlocked_status,
           role:)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  before do
    login_as(user)
    wp_page.visit!
  end

  it "locks the work package on a read only status" do
    wp_page.switch_to_tab(tab: "FILES")
    expect(page).to have_test_selector "op-attachments--drop-box"

    subject_field = wp_page.edit_field :subject
    subject_field.activate!
    subject_field.cancel_by_escape

    status_field = wp_page.edit_field :status
    status_field.expect_state_text "Unlocked"
    status_field.update "Locked"

    wp_page.expect_and_dismiss_toaster(message: "Successful update.")

    status_field.expect_state_text "Locked"

    subject_field = wp_page.edit_field :subject
    subject_field.activate! expect_open: false
    subject_field.expect_read_only

    # Expect attachments not available
    expect(page).not_to have_test_selector "op-attachments--drop-box"

    # Expect labels to not activate field editing (Regression#45032)
    assignee_field = wp_page.edit_field :assignee
    assignee_field.label_element.click
    assignee_field.expect_inactive!

    custom_field = wp_page.edit_field cf_all.attribute_name.camelcase(:lower)
    custom_field.label_element.click
    custom_field.expect_inactive!
  end
end
