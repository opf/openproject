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

RSpec.describe SquashTMIntegration::WorkPackageLinks::UpdateService do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_squashtm_test_results manage_squashtm_links] })
  end

  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:requirement) { { "id" => 11, "name" => "New name", "project" => { "id" => 1 } } }
  let!(:link) do
    create(:squashtm_work_package_link, work_package:, squashtm_requirement_id: 11, squashtm_requirement_name: "Old name")
  end

  subject(:result) { described_class.new(user:, model: link).call(squashtm_requirement_id: "11") }

  before do
    create(:squashtm_server)
    create(:squashtm_project_link, project:, squashtm_project_id: 1)
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive(:requirement).with(11).and_return(requirement)
  end

  it "refreshes the cached name when the same requirement is saved again" do
    expect(result).to be_success
    expect(link.reload.squashtm_requirement_name).to eq("New name")
  end
end
