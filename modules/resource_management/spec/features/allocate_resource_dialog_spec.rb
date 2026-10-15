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

RSpec.describe "Allocate resource dialog", :js, with_ee: %i[resource_management placeholder_users] do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners allocate_user_resources view_work_packages] })
  end
  shared_let(:resource_planner) { create(:resource_planner, project:, principal: user, public: true) }
  shared_let(:view) do
    ResourceWorkPackageList.create!(name: "WP list", parent: resource_planner, project:, principal: user)
  end

  before do
    login_as user
    visit project_resource_planner_view_path(project, resource_planner, view)
  end

  it "opens the dialog directly on the allocation form" do
    click_on I18n.t("resource_management.work_package_list.subheader.allocate")

    within_dialog do
      expect(page).to have_text(I18n.t("resource_management.allocate_resource_dialog.title"))
      expect(page).to have_field(ResourceAllocation.human_attribute_name(:placeholder_or_user))
      expect(page).to have_field(WorkPackage.model_name.human)
      expect(page).to have_field(ResourceAllocation.human_attribute_name(:allocated_hours))
      expect(page).to have_button(I18n.t("resource_management.allocate_resource_dialog.submit"))
    end
  end

  describe "the resource picker with a name nothing matches" do
    include Components::Autocompleter::NgSelectAutocompleteHelpers
    include Components::Common::Filters

    let(:autocompleter) { find("opce-resource-allocation-autocompleter") }

    def open_picker_and_search(query = "Nobody goes by this name")
      click_on I18n.t("resource_management.work_package_list.subheader.allocate")
      search_autocomplete(autocompleter,
                          query:,
                          results_selector: "##{ResourceAllocations::NewDialogComponent::DIALOG_ID}")
    end

    context "for a user who may create placeholder users" do
      shared_let(:placeholder_manager) do
        create(:user,
               global_permissions: %i[manage_placeholder_user],
               member_with_permissions: {
                 project => %i[view_resource_planners allocate_user_resources view_work_packages]
               })
      end

      before do
        login_as placeholder_manager
        visit project_resource_planner_view_path(project, resource_planner, view)
      end

      it "offers creating a placeholder user" do
        open_picker_and_search

        expect(page).to have_text(I18n.t("js.resource_management.create_placeholder_user"))
      end

      it "creates one from the searched name and picks it for the allocation" do
        open_picker_and_search("Backend Developer")
        click_on I18n.t("js.resource_management.create_placeholder_user")

        within("##{ResourceManagement::PlaceholderUsers::NewDialogComponent::DIALOG_ID}") do
          expect(page).to have_field(PlaceholderUser.human_attribute_name(:name), with: "Backend Developer")

          select_filter("name", User.human_attribute_name(:name))
          fill_in "name_value", with: "dev"

          click_on I18n.t("resource_management.create_placeholder_user_dialog.submit")
        end

        placeholder_user = PlaceholderUser.find_by(lastname: "Backend Developer")
        expect(placeholder_user.user_filter.map(&:field)).to eq([:name])

        within_dialog do
          expect(page).to have_css(".ng-value", text: "Backend Developer")
          expect(page).to have_text(I18n.t("resource_management.allocate_resource_dialog.criteria.label"))
        end
      end
    end

    context "for a user who may not create placeholder users" do
      it "offers nothing to create" do
        open_picker_and_search

        expect(page).to have_no_text(I18n.t("js.resource_management.create_placeholder_user"))
      end
    end
  end

  def within_dialog(&)
    within("##{ResourceAllocations::NewDialogComponent::DIALOG_ID}", &)
  end
end
