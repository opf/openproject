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

RSpec.describe "SquashTM project settings",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }

  let(:permissions) { %i[manage_squashtm_integration] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:settings_path) { "/projects/#{project.identifier}/settings/squashtm" }
  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:squashtm_projects) { [{ "id" => 1, "name" => "Integration Sandbox" }, { "id" => 2, "name" => "Another project" }] }

  before do
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive(:all_projects).and_return(squashtm_projects)
    allow(client).to receive(:project) { |id| squashtm_projects.find { |p| p["id"] == id } || raise(SquashTMIntegration::Client::NotFoundError) }
    login_as user
  end

  describe "GET /projects/:id/settings/squashtm" do
    subject do
      get settings_path
      response
    end

    context "with a configured server" do
      before { create(:squashtm_server) }

      it "lists the SquashTM projects to choose from" do
        expect(subject).to have_http_status(:ok)
        expect(subject.body).to include("Integration Sandbox", "Another project")
      end

      it "shows the current link" do
        create(:squashtm_project_link, project:, squashtm_project_id: 2, squashtm_project_name: "Another project")

        expect(subject.body).to include("This project is linked to the SquashTM project Another project.")
      end

      it "warns when the linked SquashTM project is no longer visible" do
        create(:squashtm_project_link, project:, squashtm_project_id: 99, squashtm_project_name: "Gone")

        expect(subject.body).to include("The linked SquashTM project Gone is no longer visible in SquashTM.")
      end

      it "explains when SquashTM is not reachable" do
        allow(client).to receive(:all_projects).and_raise(SquashTMIntegration::Client::TimeoutError)

        expect(subject).to have_http_status(:ok)
        expect(subject.body).to include("The SquashTM projects could not be loaded")
      end
    end

    context "without a configured server" do
      it "tells the user to contact the instance administrator and keeps showing the link" do
        create(:squashtm_project_link, project:, squashtm_project_name: "Integration Sandbox")

        expect(subject).to have_http_status(:ok)
        expect(subject.body).to include("Please contact your instance administrator")
        expect(subject.body).to include("This project is linked to the SquashTM project Integration Sandbox.")
        expect(SquashTMIntegration::Client).not_to have_received(:for)
      end

      it "still lists the page in the project settings menu" do
        subject

        expect(page).to have_css("#menu-sidebar .selected", text: "SquashTM")
      end
    end

    context "without the permission to manage the integration" do
      let(:permissions) { %i[view_work_packages] }

      it { is_expected.to have_http_status(:forbidden) }
    end

    context "when the SquashTM project module is disabled" do
      before { project.update!(enabled_module_names: %i[work_package_tracking]) }
      after { project.update!(enabled_module_names: %i[work_package_tracking squashtm]) }

      it { is_expected.to have_http_status(:forbidden) }
    end
  end

  describe "PATCH /projects/:id/settings/squashtm" do
    before { create(:squashtm_server) }

    it "links the project" do
      patch settings_path, params: { squashtm_project_link: { squashtm_project_id: "1" } }

      expect(response).to redirect_to(settings_path)
      expect(SquashTMIntegration::ProjectLink.sole)
        .to have_attributes(project_id: project.id, squashtm_project_id: 1, squashtm_project_name: "Integration Sandbox")
    end

    it "changes an existing link" do
      create(:squashtm_project_link, project:, squashtm_project_id: 1)

      patch settings_path, params: { squashtm_project_link: { squashtm_project_id: "2" } }

      expect(SquashTMIntegration::ProjectLink.sole)
        .to have_attributes(squashtm_project_id: 2, squashtm_project_name: "Another project")
    end

    it "asks for confirmation instead of unlinking when no SquashTM project is selected" do
      create(:squashtm_project_link, project:)

      patch settings_path,
            params: { squashtm_project_link: { squashtm_project_id: "" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("squashtm-project-link--delete-dialog")
      expect(SquashTMIntegration::ProjectLink).to exist
    end

    it "changes nothing when no SquashTM project is selected for an unlinked project" do
      patch settings_path, params: { squashtm_project_link: { squashtm_project_id: "" } }

      expect(response).to redirect_to(settings_path)
      expect(SquashTMIntegration::ProjectLink).not_to exist
    end

    it "shows the error when the SquashTM project does not exist" do
      patch settings_path, params: { squashtm_project_link: { squashtm_project_id: "99" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("does not exist or is not visible")
      expect(SquashTMIntegration::ProjectLink).not_to exist
    end
  end

  describe "GET /projects/:id/settings/squashtm/destroy_dialog" do
    it "asks for confirmation with an unlink button" do
      create(:squashtm_project_link, project:, squashtm_project_name: "Integration Sandbox")

      get "#{settings_path}/destroy_dialog", headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unlink the SquashTM project Integration Sandbox?")
      dialog = Capybara.string(Nokogiri::HTML5.fragment(response.body).at_css("template").inner_html)
      expect(dialog).to have_button("Unlink")
    end

    it "is not found when the project is not linked" do
      get "#{settings_path}/destroy_dialog", headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /projects/:id/settings/squashtm" do
    it "unlinks the project even without a configured server" do
      create(:squashtm_project_link, project:)

      delete settings_path

      expect(response).to redirect_to(settings_path)
      expect(SquashTMIntegration::ProjectLink).not_to exist
    end

    it "is not found when the project is not linked" do
      delete settings_path

      expect(response).to have_http_status(:not_found)
    end
  end
end
