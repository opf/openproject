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
  let(:permissions) { %i[manage_squashtm_links] }

  subject(:contract) { described_class.new(link, user) }

  before do
    mock_permissions_for(user) { |mock| mock.allow_in_project(*permissions, project:) }
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

    it "is invalid when the requirement could not be resolved" do
      link.change_by_system { link.squashtm_requirement_name = nil }

      expect(contract).not_to be_valid
      expect(contract.errors.details[:squashtm_requirement_id].pluck(:error)).to eq([:not_found])
    end

    it "reports a lookup error instead of a missing requirement" do
      link.change_by_system { link.squashtm_requirement_name = nil }
      link.squashtm_requirement_lookup_error = :squashtm_unavailable

      expect(contract).not_to be_valid
      expect(contract.errors.details[:squashtm_requirement_id].pluck(:error)).to eq([:squashtm_unavailable])
    end
  end

  context "without the permission to manage requirement links" do
    let(:permissions) { %i[view_squashtm_test_results] }

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
