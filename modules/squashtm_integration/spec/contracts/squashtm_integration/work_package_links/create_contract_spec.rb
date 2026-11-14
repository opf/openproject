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

RSpec.describe SquashTMIntegration::WorkPackageLinks::CreateContract do
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:link) do
    SquashTMIntegration::WorkPackageLink.new(work_package:, squashtm_requirement_id: 11).tap do |link|
      link.extend(OpenProject::ChangedBySystem)
      link.change_by_system { link.squashtm_requirement_name = "Users can sign in" }
    end
  end
  let(:user) { build_stubbed(:user) }
  let(:permissions) { %i[manage_squashtm_requirements] }

  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:requirement) { { "id" => 11, "name" => "Users can sign in", "project" => { "id" => 1 } } }

  subject(:contract) { described_class.new(link, user) }

  before do
    mock_permissions_for(user) { |mock| mock.allow_in_project(*permissions, project:) }
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive(:requirement).with(11).and_return(requirement)
  end

  context "with a configured server and a linked project" do
    before do
      create(:squashtm_server)
      create(:squashtm_project_link, project:)
    end

    it "is valid for a resolved requirement" do
      expect(contract).to be_valid
    end

    it "requires a requirement" do
      link.squashtm_requirement_id = nil

      expect(contract).not_to be_valid
      expect(contract.errors.details[:squashtm_requirement_id].pluck(:error)).to include(:blank)
    end

    it "is invalid when the requirement does not exist" do
      allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::NotFoundError.new(404))

      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to eq([:squashtm_requirement_not_found])
    end

    it "is invalid when SquashTM is not reachable" do
      allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::TimeoutError)

      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to eq([:squashtm_requirement_unavailable])
    end

    it "is invalid when the requirement belongs to another SquashTM project" do
      requirement["project"]["id"] = 2

      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to eq([:squashtm_requirement_not_in_linked_project])
    end
  end

  context "without the permission to manage requirement links" do
    let(:permissions) { %i[view_squashtm] }

    before do
      create(:squashtm_server)
      create(:squashtm_project_link, project:)
    end

    it "is invalid" do
      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to eq([:error_unauthorized])
    end
  end

  context "without a configured server" do
    it "is invalid" do
      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to eq([:squashtm_server_not_configured])
    end
  end

  context "when the project is not linked to a SquashTM project" do
    before { create(:squashtm_server) }

    it "is invalid" do
      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to eq([:squashtm_project_not_linked])
    end
  end
end
