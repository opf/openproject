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

RSpec.describe SquashTMIntegration::ProjectLinks::CreateContract do
  let(:project) { build_stubbed(:project) }
  let(:link) do
    SquashTMIntegration::ProjectLink.new(project:, squashtm_project_id: 7).tap do |link|
      link.extend(OpenProject::ChangedBySystem)
      link.change_by_system { link.squashtm_project_name = "Integration Sandbox" }
    end
  end
  let(:user) { build_stubbed(:user) }
  let(:permissions) { %i[manage_squashtm_integration] }

  subject(:contract) { described_class.new(link, user) }

  before do
    mock_permissions_for(user) { |mock| mock.allow_in_project(*permissions, project:) }
  end

  context "with a configured server" do
    before { create(:squashtm_server) }

    it "is valid for a resolved SquashTM project" do
      expect(contract).to be_valid
    end

    it "requires a SquashTM project" do
      link.squashtm_project_id = nil

      expect(contract).not_to be_valid
      expect(contract.errors.details[:squashtm_project_id].pluck(:error)).to include(:blank)
    end

    it "is invalid when the SquashTM project could not be resolved" do
      link.change_by_system { link.squashtm_project_name = nil }

      expect(contract).not_to be_valid
      expect(contract.errors.details[:squashtm_project_id].pluck(:error)).to eq([:not_found])
    end

    it "reports a lookup error instead of a missing project" do
      link.change_by_system { link.squashtm_project_name = nil }
      link.squashtm_project_lookup_error = :squashtm_unavailable

      expect(contract).not_to be_valid
      expect(contract.errors.details[:squashtm_project_id].pluck(:error)).to eq([:squashtm_unavailable])
    end
  end

  context "without the permission to manage the SquashTM integration" do
    let(:permissions) { %i[] }

    before { create(:squashtm_server) }

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
end
