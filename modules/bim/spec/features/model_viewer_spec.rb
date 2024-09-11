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

RSpec.describe "model viewer", :js, with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  # TODO: Add empty viewpoint and stub method to load viewpoints once defined
  let(:work_package) { create(:work_package, project:) }
  let(:role) { create(:project_role, permissions: %i[view_ifc_models manage_ifc_models view_work_packages]) }

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let!(:model) do
    create(:ifc_model_minimal_converted,
           project:,
           uploader: user)
  end

  let(:show_model_page) { Pages::IfcModels::Show.new(project, model.id) }
  let(:model_tree) { Components::XeokitModelTree.new }
  let(:card_view) { Pages::WorkPackageCards.new(project) }

  context "with all permissions" do
    describe "showing a model" do
      before do
        login_as(user)
        work_package
        show_model_page.visit_and_wait_until_finished_loading!
      end

      it "loads and shows the viewer correctly" do
        show_model_page.model_viewer_visible true
        show_model_page.model_viewer_shows_a_toolbar true
        show_model_page.page_shows_a_toolbar true
        model_tree.sidebar_shows_viewer_menu true
        model_tree.expect_model_management_available visible: true
      end

      it "shows a work package list as cards next to the viewer" do
        show_model_page.model_viewer_visible true
        card_view.expect_work_package_listed work_package
      end

      it "can trigger creation, update and deletion of IFC models from within the model tree view" do
        model_tree.click_add_model
        expect(page).to have_current_path new_bcf_project_ifc_model_path(project)

        show_model_page.visit_and_wait_until_finished_loading!

        model_tree.select_model_menu_item(model.title, "Edit")
        expect(page).to have_current_path edit_bcf_project_ifc_model_path(project, model.id)

        show_model_page.visit_and_wait_until_finished_loading!

        model_tree.select_model_menu_item(model.title, "Delete")
        show_model_page.finished_loading
        expect(page).to have_text(I18n.t("js.ifc_models.empty_warning"))
      end
    end

    context "in a project with no model" do
      let!(:model) { nil }

      it "shows a warning that no IFC models exist yet" do
        login_as user
        visit defaults_bcf_project_ifc_models_path(project)
        expect(page).to have_css(".op-toast.-info", text: I18n.t("js.ifc_models.empty_warning"))
      end
    end
  end

  context "with only viewing permissions" do
    let(:view_role) { create(:project_role, permissions: %i[view_ifc_models view_work_packages view_linked_issues]) }
    let(:view_user) do
      create(:user,
             member_with_roles: { project => view_role })
    end

    before do
      login_as(view_user)
      show_model_page.visit_and_wait_until_finished_loading!
    end

    it "loads and shows the viewer correctly, but has no possibility to edit the model" do
      show_model_page.model_viewer_visible true
      show_model_page.model_viewer_shows_a_toolbar true
      show_model_page.page_shows_a_toolbar false
      model_tree.sidebar_shows_viewer_menu true
      model_tree.expect_model_management_available visible: false
    end
  end

  context "without any permissions" do
    let(:no_permissions_role) { create(:project_role, permissions: %i[]) }
    let(:user_without_permissions) do
      create(:user,
             member_with_roles: { project => no_permissions_role })
    end

    before do
      login_as(user_without_permissions)
      work_package
      show_model_page.visit!
    end

    it "shows no viewer" do
      expected = "[Error 403] You are not authorized to access this page."
      expect(page).to have_css(".op-toast.-error", text: expected)

      show_model_page.model_viewer_visible false
      show_model_page.model_viewer_shows_a_toolbar false
      show_model_page.page_shows_a_toolbar false
      model_tree.sidebar_shows_viewer_menu false
    end

    it "shows no work package list next to the viewer" do
      show_model_page.model_viewer_visible false
      card_view.expect_work_package_not_listed work_package
    end
  end
end
