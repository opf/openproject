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

RSpec.describe "Linking SquashTM requirements to work packages",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_links] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:link_path) { "/projects/#{project.id}/work_packages/#{work_package.id}/squashtm_requirement_link" }
  let(:tab_path) { "/projects/#{project.identifier}/work_packages/#{work_package.id}/squashtm/tab" }
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    create(:squashtm_server)
    create(:squashtm_project_link, project:, squashtm_project_id: 1)
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive_messages(requirement: { "id" => 11, "name" => "Users can sign in", "project" => { "id" => 1 } },
                                      all_requirements: [{ "id" => 11, "name" => "Users can sign in" }])
    login_as user
  end

  describe "PATCH" do
    it "links the requirement and reloads the tab" do
      patch link_path, params: { squashtm_work_package_link: { squashtm_requirement_id: "11" } }, headers: turbo_stream

      expect(response).to redirect_to(tab_path)
      expect(SquashTMIntegration::WorkPackageLink.sole)
        .to have_attributes(work_package_id: work_package.id, squashtm_requirement_id: 11)
    end

    it "re-renders the tab with the error when the requirement cannot be linked" do
      allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::NotFoundError)

      patch link_path, params: { squashtm_work_package_link: { squashtm_requirement_id: "11" } }, headers: turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("turbo-stream", "does not exist or is not visible")
      expect(SquashTMIntegration::WorkPackageLink).not_to exist
    end

    context "without the permission to manage links" do
      let(:permissions) { %i[view_work_packages view_squashtm_test_results] }

      it "is forbidden" do
        patch link_path, params: { squashtm_work_package_link: { squashtm_requirement_id: "11" } }, headers: turbo_stream

        expect(response).to have_http_status(:forbidden)
        expect(SquashTMIntegration::WorkPackageLink).not_to exist
      end
    end
  end

  describe "GET destroy_dialog" do
    it "asks for confirmation" do
      create(:squashtm_work_package_link, work_package:)

      get "#{link_path}/destroy_dialog", headers: turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("op-work-package-squashtm-tab--unlink-dialog")
      dialog = Capybara.string(Nokogiri::HTML5.fragment(response.body).at_css("template").inner_html)
      expect(dialog).to have_button("Unlink")
    end
  end

  describe "DELETE" do
    it "unlinks the requirement and reloads the tab" do
      create(:squashtm_work_package_link, work_package:)

      delete link_path, headers: turbo_stream

      expect(response).to redirect_to(tab_path)
      expect(SquashTMIntegration::WorkPackageLink).not_to exist
    end

    it "is not found when no requirement is linked" do
      delete link_path, headers: turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end
end
