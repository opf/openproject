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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Editing the assignee of a resource allocation", :js, with_ee: %i[resource_management] do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages view_resource_planners allocate_user_resources] })
  end
  shared_let(:assignee) do
    create(:user, firstname: "Dev", lastname: "One", member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:other_member) do
    create(:user, firstname: "Dev", lastname: "Two", member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:non_candidate) do
    create(:user, firstname: "Ops", lastname: "Three", member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:placeholder) do
    filters = UserQuery.new.tap { |query| query.where("name", "~", ["dev"]) }.filters
    create(:placeholder_user, name: "Senior Developer", user_filter: filters)
  end
  shared_let(:deleted_user) { create(:deleted_user) }
  shared_let(:work_package) { create(:work_package, project:, estimated_hours: 16) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:allocated_time_field) { EditField.new(page, "allocatedTime") }
  let(:autocompleter) { find("opce-resource-allocation-autocompleter") }
  let(:edit_dialog_selector) { "##{ResourceAllocations::EditDialogComponent::DIALOG_ID}" }

  before { login_as(user) }

  def open_edit_dialog
    wp_page.visit!
    within(allocated_time_field.field_container) { click_button I18n.t("js.resource_management.show_allocations") }

    within("##{ResourceAllocations::ListDialogComponent::DIALOG_ID}") do
      all(:button) { it.has_selector?("svg.octicon-kebab-horizontal") }.first.click
    end
    find(:menuitem, I18n.t(:button_edit)).click

    expect(page).to have_css(edit_dialog_selector)
  end

  def save_with_hours(hours)
    within(edit_dialog_selector) do
      fill_in ResourceAllocation.human_attribute_name(:allocated_hours), with: hours
      click_on I18n.t("resource_management.edit_allocation_dialog.submit")
    end

    expect(page).to have_text(I18n.t("resource_management.edit_allocation_dialog.success_message"))
  end

  context "for an allocation assigned directly to a user who was deleted" do
    let!(:allocation) do
      create(:resource_allocation, entity: work_package, principal: deleted_user, allocated_time: 8 * 60)
    end

    it "shows the deleted user, explains the deletion and keeps them when only the hours change" do
      open_edit_dialog

      within(edit_dialog_selector) do
        expect_current_autocompleter_value(autocompleter, deleted_user.name)
        expect(page).to have_text(I18n.t("resource_management.allocate_resource_dialog.deleted_assignee"))
      end

      save_with_hours("16h")

      allocation.reload
      expect(allocation.allocated_time).to eq(16 * 60)
      expect(allocation.principal).to eq(deleted_user)
    end
  end

  context "for a staffed allocation" do
    let!(:allocation) do
      create(:resource_allocation, entity: work_package, placeholder_user: placeholder, principal: assignee,
                                   allocated_time: 8 * 60)
    end

    it "shows the assigned user, offers only the placeholder's candidates and re-staffs on a new pick" do
      open_edit_dialog

      within(edit_dialog_selector) do
        expect_current_autocompleter_value(autocompleter, assignee.name)
        expect(page).to have_text(
          I18n.t("resource_management.allocate_resource_dialog.staffed_from", placeholder: placeholder.name)
        )
      end

      search_autocomplete(autocompleter, query: "e", results_selector: edit_dialog_selector)
      expect_ng_option(autocompleter, other_member.name, results_selector: edit_dialog_selector)
      expect_no_ng_option(autocompleter, non_candidate.name, results_selector: edit_dialog_selector)
      expect_no_ng_option(autocompleter, placeholder.name, results_selector: edit_dialog_selector)

      select_autocomplete(autocompleter, query: other_member.lastname, select_text: other_member.name,
                                         results_selector: edit_dialog_selector)
      save_with_hours("8h")

      allocation.reload
      expect(allocation.principal).to eq(other_member)
      expect(allocation.placeholder_user).to eq(placeholder)
      expect(allocation.principal_assigned_by).to eq(user)
    end
  end
end
