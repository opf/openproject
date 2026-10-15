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

RSpec.describe "Allocated time field on the work package page", :js, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages view_resource_planners allocate_user_resources] })
  end
  shared_let(:work_package) { create(:work_package, project:, estimated_hours: 16) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:allocated_time_field) { EditField.new(page, "allocatedTime") }

  before do
    create(:resource_allocation, entity: work_package, principal: user, allocated_time: 8 * 60)
    create(:resource_allocation, entity: work_package, principal: user, allocated_time: 4 * 60)

    login_as(user)
    wp_page.visit!
  end

  it "shows the allocated time against the work and opens the allocations dialog" do
    allocated_time_field.expect_state_text("12h / 16h (75%)")

    within(allocated_time_field.field_container) { click_button I18n.t("js.resource_management.show_allocations") }

    within("##{ResourceAllocations::ListDialogComponent::DIALOG_ID}") do
      expect(page).to have_text(I18n.t("resource_management.work_package_allocations_dialog.title"))
    end
  end

  it "updates after an allocation is removed in the dialog" do
    within(allocated_time_field.field_container) { click_button I18n.t("js.resource_management.show_allocations") }

    within("##{ResourceAllocations::ListDialogComponent::DIALOG_ID}") do
      all(:button) { it.has_selector?("svg.octicon-kebab-horizontal") }.first.click
    end
    accept_confirm { find(:menuitem, I18n.t(:button_delete)).click }

    allocated_time_field.expect_state_text("4h / 16h (25%)")
  end
end
