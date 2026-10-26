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

RSpec.describe "Work package SquashTM tab",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages view_squashtm_test_results] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  let(:client) { instance_double(SquashTMIntegration::Client) }

  subject do
    get "/projects/#{project.id}/work_packages/#{work_package.id}/squashtm/tab"
    response
  end

  before do
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive(:all_requirements).and_return([{ "id" => 11, "name" => "Users can sign in" }])
    login_as user
  end

  it "tells the user when no SquashTM server is configured" do
    expect(subject).to have_http_status(:ok)
    expect(subject.body).to include("work-package-squashtm-tab-content")
    expect(subject.body).to include("SquashTM is not available")
    expect(SquashTMIntegration::Client).not_to have_received(:for)
  end

  context "with a configured server" do
    before { create(:squashtm_server) }

    it "tells the user when the project is not linked to a SquashTM project" do
      expect(subject).to have_http_status(:ok)
      expect(subject.body).to include("No SquashTM project linked")
    end

    context "and a linked project" do
      before { create(:squashtm_project_link, project:, squashtm_project_id: 1) }

      it "shows that no requirement is linked yet" do
        expect(subject).to have_http_status(:ok)
        expect(subject.body).to include("No SquashTM requirement linked")
        expect(subject.body).not_to include("Link requirement")
      end

      context "for a user allowed to manage links" do
        let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_links] }

        it "offers the requirements to link" do
          expect(subject.body).to include("Link requirement", "Users can sign in")
        end

        it "explains when SquashTM is not reachable" do
          allow(client).to receive(:all_requirements).and_raise(SquashTMIntegration::Client::SsrfError)

          expect(subject).to have_http_status(:ok)
          expect(subject.body).to include("The SquashTM requirements could not be loaded")
        end
      end

      context "and a linked requirement" do
        before { create(:squashtm_work_package_link, work_package:, squashtm_requirement_name: "Users can sign in") }

        it "shows the linked requirement without an unlink action" do
          page = Capybara.string(subject.body)

          expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--requirement']",
                                   text: "Users can sign in")
          expect(page).to have_no_css("[data-test-selector='op-work-package-squashtm-tab--unlink']")
        end

        context "for a user allowed to manage links" do
          let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_links] }

          it "offers to unlink the requirement" do
            expect(Capybara.string(subject.body)).to have_css("[data-test-selector='op-work-package-squashtm-tab--unlink']")
          end
        end
      end
    end
  end

  context "without the permission to view SquashTM test results" do
    let(:permissions) { %i[view_work_packages] }

    it { is_expected.to have_http_status(:forbidden) }
  end

  context "when the SquashTM project module is disabled" do
    before do
      project.enabled_module_names = %i[work_package_tracking]
    end

    it { is_expected.to have_http_status(:forbidden) }
  end
end
