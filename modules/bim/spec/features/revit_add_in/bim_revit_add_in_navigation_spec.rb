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

require_relative "../../spec_helper"

RSpec.describe "BIM Revit Add-in navigation spec", :js,
               driver: :chrome_revit_add_in, with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  let!(:work_package) { create(:work_package, project:) }
  let(:role) do
    create(:project_role,
           permissions: %i[view_ifc_models manage_ifc_models add_work_packages edit_work_packages view_work_packages])
  end
  let(:model_page) { Pages::IfcModels::ShowDefault.new(project) }

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  context "when logged in on model page" do
    before do
      login_as(user)
      model_page.visit!

      # Guard to ensure toolbar is completely loaded and doesn't rerender again.
      # At first there is no badge. It gets set later and only then the toolbar's
      # switches are ready to test.
      model_page.find("#work-packages-filter-toggle-button .badge", text: "1")
    end

    let(:full_create) { Pages::FullWorkPackageCreate.new }

    it "show the right elements on the page" do
      # shows "Cards" view by default
      model_page.expect_view_toggle_at "Cards"
      # shows no viewer
      model_page.model_viewer_visible false
      # shows a toolbar' do
      model_page.page_has_a_toolbar
      # menu has no viewer options
      model_page.has_no_menu_item_with_text? "Viewer"
    end

    it "the user menu has an option to go to the add-in settings" do
      within ".op-app-header" do
        page.find("a[title='#{user.name}']").click

        expect(page).to have_css("li", text: I18n.t("js.revit.revit_add_in_settings"))
      end
    end

    it "opens new work package form in full view" do
      find(".add-work-package", wait: 10).click
      # The only type to select is 'NONE'
      find(".menu-item", text: "NONE", wait: 10).click

      full_create.edit_field(:subject).expect_active!
      expect(page).to have_css(".work-packages-partitioned-page--content-right", visible: :all)
    end

    it "shows work package details page in full view on Cards display mode" do
      model_page.click_info_icon(work_package)

      expect(page).to have_css(".work-packages-partitioned-page--content-left", text: work_package.subject)
      expect(page).to have_css(".work-packages-partitioned-page--content-right", visible: :all)
    end

    context "with the table display mode" do
      let(:wp_table) { Pages::WorkPackagesTable.new(project) }

      it "shows work package details page in full view on Table display mode" do
        model_page.switch_view "Table"
        loading_indicator_saveguard

        expect(page).to have_css(".work-package-table")
        wp_table.expect_work_package_listed work_package
        wp_table.open_split_view work_package

        expect(page).to have_css(".work-packages-partitioned-page--content-left", text: work_package.subject)
        expect(page).to have_css(".work-packages-partitioned-page--content-right", visible: false)
      end
    end

    context "Creating BCFs" do
      let!(:status) { create(:default_status) }
      let!(:priority) { create(:priority, is_default: true) }

      it "redirects correctly" do
        create_page = model_page.create_wp_by_button(build(:type_standard))
        expect(page).to have_current_path /bcf\/new$/, ignore_query: true
        create_page.subject_field.set("Some subject")
        create_page.save!

        sleep(5)
        last_work_package = WorkPackage.find_by(subject: "Some subject")
        # The currently working routes seem weird as they duplicate the work package ID.
        expect(page).to(
          have_current_path(/bcf\/show\/#{last_work_package.id}\/details\/#{last_work_package.id}\/overview$/,
                            ignore_query: true)
        )
      end
    end
  end

  context "when signed out" do
    it "the user menu has an option to go to the add-in settings" do
      visit home_path

      click_link I18n.t(:label_login)

      expect(page).to have_text(I18n.t("js.revit.revit_add_in_settings"))
    end
  end
end
