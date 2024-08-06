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

require_relative "../spec_helper"

RSpec.describe "BIM navigation spec", :js, with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  let!(:work_package) { create(:work_package, project:) }
  let(:role) do
    create(:project_role, permissions: %i[view_ifc_models manage_ifc_models view_work_packages delete_work_packages])
  end

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let(:model) do
    create(:ifc_model_minimal_converted,
           project:,
           uploader: user)
  end

  let(:card_view) { Pages::WorkPackageCards.new(project) }
  let(:details_view) { Pages::BcfDetailsPage.new(work_package, project) }
  let(:full_view) { Pages::FullWorkPackage.new(work_package) }
  let(:model_tree) { Components::XeokitModelTree.new }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }

  before do
    login_as user
    model
  end

  shared_examples "can switch from split to viewer to list-only" do
    before do
      model_page.visit!
      model_page.finished_loading
    end

    context "deep link on the page" do
      before do
        model_page.visit!
        model_page.finished_loading

        # Should be at split view
        model_page.model_viewer_visible true
        model_page.model_viewer_shows_a_toolbar true
        model_page.page_shows_a_toolbar true
        model_tree.sidebar_shows_viewer_menu true
        expect(page).to have_test_selector("op-wp-card-view")
        card_view.expect_work_package_listed work_package
      end

      it "can switch between the different view modes" do
        # Opening details view with info icon
        card_view.click_info_icon(work_package)

        details_view.ensure_page_loaded
        details_view.expect_subject
        details_view.switch_to_tab tab: "Activity"
        details_view.expect_tab "Activity"

        # Going to full screen and back again
        details_view.switch_to_fullscreen
        full_view.expect_tab "Activity"
        full_view.go_back

        details_view.ensure_page_loaded
        details_view.expect_subject
        details_view.go_back

        details_view.expect_closed
        card_view.expect_work_package_listed(work_package)

        # Go to viewer only
        model_page.switch_view "Viewer"

        model_page.model_viewer_visible true
        expect(page).not_to have_test_selector("op-wp-card-view")

        # Go to list only
        model_page.switch_view "Cards"

        model_page.model_viewer_visible false
        expect(page).to have_test_selector("op-wp-card-view")
        card_view.expect_work_package_listed work_package

        # Go to details view
        card_view.click_id_link(work_package)

        details_view.ensure_page_loaded
        details_view.expect_subject
        details_view.switch_to_tab tab: "Activity"
        details_view.expect_tab "Activity"
        details_view.close
        details_view.expect_closed
      end

      it "after deleting an WP in full view it returns to the model and list view (see #33317)" do
        # Go to full single view
        card_view.open_split_view_by_info_icon(work_package)
        details_view.switch_to_fullscreen
        full_view.expect_tab "Activity"

        # Delete via the context menu
        find("#action-show-more-dropdown-menu .button").click
        find(".menu-item", text: "Delete").click

        destroy_modal.expect_listed(work_package)
        destroy_modal.confirm_deletion

        # Expect to return to the start page with closed details view and delete WP
        model_page.model_viewer_visible true
        details_view.expect_closed
        card_view.expect_work_package_not_listed work_package
      end

      it "after going to the full view with a selected tab, " \
         "the same tab should be opened in full screen view and after going back to details view(see #33747)" do
        card_view.open_split_view_by_info_icon(work_package)

        details_view.ensure_page_loaded
        details_view.expect_subject
        details_view.switch_to_tab tab: "Relations"

        details_view.switch_to_fullscreen
        full_view.expect_tab "Relations"

        full_view.go_back
        details_view.expect_tab "Relations"
      end
    end
  end

  context "on default page" do
    let(:model_page) { Pages::IfcModels::ShowDefault.new project }

    it_behaves_like "can switch from split to viewer to list-only"
  end

  context "on show page" do
    let(:model_page) { Pages::IfcModels::Show.new project, model.id }

    it_behaves_like "can switch from split to viewer to list-only"
  end
end
