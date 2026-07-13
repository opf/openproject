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

RSpec.describe "Allocate resource dialog", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners allocate_user_resources view_work_packages] })
  end
  shared_let(:resource_planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:view) do
    ResourceWorkPackageList.create!(name: "WP list", parent: resource_planner, project:, principal: user)
  end

  before do
    login_as user
    visit project_resource_planner_view_path(project, resource_planner, view)
  end

  it "opens the dialog and advances from the kind step to the allocation step" do
    click_on I18n.t("resource_management.work_package_list.subheader.allocate")

    within_dialog do
      expect(page).to have_text(I18n.t("resource_management.allocate_resource_dialog.title"))
      expect(page).to have_text(I18n.t("resource_management.allocate_resource_dialog.kind.principal.label"))
      expect(page).to have_text(I18n.t("resource_management.allocate_resource_dialog.kind.filter.label"))

      # "User" is selected by default — advance to step 2.
      click_on I18n.t("button_next")

      expect(page).to have_field(WorkPackage.model_name.human)
      expect(page).to have_field(ResourceAllocation.human_attribute_name(:allocated_hours))
      expect(page).to have_button(I18n.t("resource_management.allocate_resource_dialog.submit"))
    end
  end

  it "shows the filter criteria builder on the filter step" do
    click_on I18n.t("resource_management.work_package_list.subheader.allocate")

    within_dialog do
      choose I18n.t("resource_management.allocate_resource_dialog.kind.filter.label")
      click_on I18n.t("button_next")

      expect(page).to have_field(ResourceAllocation.human_attribute_name(:filter_name))
      # The blank UserQuery filter form renders its "add filter" selector.
      expect(page).to have_css(".op-filters-form")
    end
  end

  def within_dialog(&)
    within("##{ResourceAllocations::NewDialogComponent::DIALOG_ID}", &)
  end
end
