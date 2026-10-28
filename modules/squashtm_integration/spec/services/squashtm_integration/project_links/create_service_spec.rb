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

RSpec.describe SquashTMIntegration::ProjectLinks::CreateService, :webmock do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[manage_squashtm_integration] }) }

  let(:project_url) { "https://squashtm.example.com/squash/api/rest/latest/projects/7" }

  subject(:result) { described_class.new(user:).call(project:, squashtm_project_id: "7") }

  context "with a configured server" do
    before { create(:squashtm_server) }

    it "links the project and caches the SquashTM project name" do
      stub_request(:get, project_url).to_return(status: 200, body: { id: 7, name: "Sandbox" }.to_json)

      expect(result).to be_success
      expect(result.result).to have_attributes(project:, squashtm_project_id: 7, squashtm_project_name: "Sandbox")
      expect(SquashTMIntegration::ProjectLink.count).to eq(1)
    end

    it "fails when the SquashTM project does not exist" do
      stub_request(:get, project_url).to_return(status: 404)

      expect(result).to be_failure
      expect(result.errors.details[:squashtm_project_id].pluck(:error)).to eq([:not_found])
      expect(SquashTMIntegration::ProjectLink).not_to exist
    end

    it "fails when SquashTM is not reachable" do
      stub_request(:get, project_url).to_timeout

      expect(result).to be_failure
      expect(result.errors.details[:squashtm_project_id].pluck(:error)).to eq([:squashtm_unavailable])
    end

    it "allows several OpenProject projects to link the same SquashTM project" do
      stub_request(:get, project_url).to_return(status: 200, body: { id: 7, name: "Sandbox" }.to_json)
      create(:squashtm_project_link, squashtm_project_id: 7)

      expect(result).to be_success
    end

    context "without the permission to manage the integration" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      it "fails" do
        stub_request(:get, project_url).to_return(status: 200, body: { id: 7, name: "Sandbox" }.to_json)

        expect(result).to be_failure
        expect(result.errors.details[:base].pluck(:error)).to include(:error_unauthorized)
      end
    end
  end

  context "without a configured server" do
    it "fails without contacting SquashTM" do
      expect(result).to be_failure
      expect(result.errors.details[:base].pluck(:error)).to include(:squashtm_server_not_configured)
      expect(WebMock).not_to have_requested(:any, /squashtm/)
    end
  end
end
