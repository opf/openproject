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

require "spec_helper"

RSpec.describe "SquashTM project settings", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }

  let(:permissions) { %i[manage_squashtm_integration view_work_packages] }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions }, preferences: { warn_on_leaving_unsaved: false })
  end
  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:squashtm_projects) { [{ "id" => 2, "name" => "Webshop" }, { "id" => 1, "name" => "Integration Sandbox" }] }

  before do
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive_messages(all_projects: squashtm_projects, project: { "id" => 1, "name" => "Integration Sandbox" })

    login_as(user)
  end

  context "without a configured SquashTM server" do
    it "tells the project admin to contact the instance administrator" do
      visit project_settings_squashtm_path(project)

      expect(page).to have_test_selector("squashtm-project-link--no-server")
    end
  end

  context "with a configured SquashTM server" do
    before { create(:squashtm_server) }

    it "links the project to a SquashTM project and unlinks it again" do
      visit project_settings_squashtm_path(project)

      select "Integration Sandbox", from: "SquashTM project"
      click_button "Save"

      expect_flash(message: I18n.t(:notice_successful_update))
      within_test_selector("squashtm-project-link--current") do
        expect(page).to have_text("This project is linked to the SquashTM project Integration Sandbox")
        expect(page).to have_link(
          "Integration Sandbox",
          href: "https://squashtm.example.com/squash/administration-workspace/projects/1/content?anchor=information"
        )
      end
      expect(page).to have_no_select("SquashTM project")
      expect(SquashTMIntegration::ProjectLink.sole).to have_attributes(project_id: project.id, squashtm_project_id: 1)

      find_test_selector("squashtm-project-link--delete").click
      within_test_selector("squashtm-project-link--delete-dialog") do
        expect(page).to have_text("Unlink the SquashTM project Integration Sandbox?")
        click_button "Unlink"
      end

      expect_flash(message: "The SquashTM project was unlinked.")
      expect(SquashTMIntegration::ProjectLink).not_to exist
    end

    it "lists the SquashTM projects by name" do
      visit project_settings_squashtm_path(project)

      expect(page).to have_select("SquashTM project", options: ["Select a SquashTM project", "Integration Sandbox", "Webshop"])
    end

    it "shows the error when the SquashTM project does not exist" do
      allow(client).to receive(:project).and_raise(SquashTMIntegration::Client::NotFoundError)
      visit project_settings_squashtm_path(project)

      select "Webshop", from: "SquashTM project"
      click_button "Save"

      expect(page).to have_text("does not exist or is not visible to the SquashTM account")
      expect(SquashTMIntegration::ProjectLink).not_to exist
    end

    it "shows the linked SquashTM project with an unlink button" do
      create(:squashtm_project_link, project:, squashtm_project_id: 1, squashtm_project_name: "Integration Sandbox")
      visit project_settings_squashtm_path(project)

      expect(page).to have_test_selector("squashtm-project-link--current", text: "Integration Sandbox")
      expect(page).to have_test_selector("squashtm-project-link--delete", text: "Unlink")
      expect(page).to have_no_select("SquashTM project")
      expect(find_link("Integration Sandbox")[:target]).to eq("_blank")
    end

    context "when work packages are linked to SquashTM requirements" do
      let(:work_package) { create(:work_package, project:, subject: "Sign-in page") }

      before do
        create(:squashtm_project_link, project:, squashtm_project_id: 1, squashtm_project_name: "Integration Sandbox")
        create(:squashtm_work_package_link, work_package:)
      end

      context "with the permission to manage requirement links" do
        let(:permissions) { %i[manage_squashtm_integration manage_squashtm_links view_work_packages] }

        it "unlinks the project together with its linked work packages only after explicit confirmation" do
          visit project_settings_squashtm_path(project)

          find_test_selector("squashtm-project-link--delete").click
          dialog = find_test_selector("squashtm-project-link--delete-dialog")
          wait_for_size_animation_completion(dialog)

          within(dialog) do
            expect(page).to have_text("1 work package is still linked to a SquashTM requirement:")
            expect(page).to have_link("##{work_package.id} Sign-in page")
            expect(page).to have_button("Unlink", disabled: true)

            check I18n.t("squashtm_integration.project_settings.delete_project_link_dialog_component.unlink_work_packages",
                         count: 1)
            click_button "Unlink"
          end

          expect_flash(message: "The SquashTM project was unlinked.")
          expect(SquashTMIntegration::ProjectLink).not_to exist
          expect(SquashTMIntegration::WorkPackageLink).not_to exist
        end
      end

      context "without the permission to manage requirement links" do
        it "explains that the project cannot be unlinked yet" do
          visit project_settings_squashtm_path(project)

          find_test_selector("squashtm-project-link--delete").click
          dialog = find_test_selector("squashtm-project-link--delete-dialog")
          wait_for_size_animation_completion(dialog)

          within(dialog) do
            expect(page).to have_test_selector("squashtm-project-link--unlink-blocked")
            expect(page).to have_link("##{work_package.id} Sign-in page")
            expect(page).to have_no_button("Unlink")
            click_button "Close"
          end

          expect(page).to have_no_test_selector("squashtm-project-link--delete-dialog")
          expect(SquashTMIntegration::ProjectLink).to exist
        end
      end
    end

    context "without the permission to manage the integration" do
      let(:permissions) { %i[view_work_packages] }

      it "is forbidden" do
        visit project_settings_squashtm_path(project)

        expect(page).to have_text("You are not authorized to access this page.")
      end
    end
  end
end
