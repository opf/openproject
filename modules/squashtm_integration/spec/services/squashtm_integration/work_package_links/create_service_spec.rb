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

RSpec.describe SquashTMIntegration::WorkPackageLinks::CreateService do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_links] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:requirement) { { "id" => 11, "name" => "Users can sign in", "project" => { "id" => 1 } } }

  subject(:result) { described_class.new(user:).call(work_package:, squashtm_requirement_id: "11") }

  before do
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive(:requirement).with(11).and_return(requirement)
  end

  context "with a configured server and a linked project" do
    before do
      create(:squashtm_server)
      create(:squashtm_project_link, project:, squashtm_project_id: 1)
    end

    it "links the work package and caches the requirement name" do
      expect(result).to be_success
      expect(result.result).to have_attributes(work_package:, squashtm_requirement_id: 11,
                                               squashtm_requirement_name: "Users can sign in")
    end

    it "allows several work packages to link the same requirement" do
      create(:squashtm_work_package_link, work_package: create(:work_package, project:), squashtm_requirement_id: 11)

      expect(result).to be_success
    end

    it "rejects a second requirement for the same work package" do
      create(:squashtm_work_package_link, work_package:, squashtm_requirement_id: 12)

      expect(result).to be_failure
      expect(result.errors.details[:work_package_id].pluck(:error)).to include(:taken)
    end

    it "rejects a requirement of another SquashTM project" do
      requirement["project"]["id"] = 2

      expect(result).to be_failure
      expect(result.errors.details[:squashtm_requirement_id].pluck(:error)).to eq([:not_in_linked_project])
    end

    it "rejects a requirement that does not exist" do
      allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::NotFoundError)

      expect(result).to be_failure
      expect(result.errors.details[:squashtm_requirement_id].pluck(:error)).to eq([:not_found])
    end

    it "fails when SquashTM is not reachable" do
      allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::SsrfError)

      expect(result).to be_failure
      expect(result.errors.details[:squashtm_requirement_id].pluck(:error)).to eq([:squashtm_unavailable])
    end

    context "without the permission to manage links" do
      let(:permissions) { %i[view_work_packages view_squashtm_test_results] }

      it "fails" do
        expect(result).to be_failure
        expect(result.errors.details[:base].pluck(:error)).to include(:error_unauthorized)
      end
    end
  end

  context "when the project is not linked to a SquashTM project" do
    before { create(:squashtm_server) }

    it "fails without contacting SquashTM" do
      expect(result).to be_failure
      expect(result.errors.details[:base].pluck(:error)).to include(:squashtm_project_not_linked)
      expect(client).not_to have_received(:requirement)
    end
  end

  context "without a configured server" do
    it "fails without contacting SquashTM" do
      expect(result).to be_failure
      expect(result.errors.details[:base].pluck(:error)).to include(:squashtm_server_not_configured)
      expect(SquashTMIntegration::Client).not_to have_received(:for)
    end
  end
end
