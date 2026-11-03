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

RSpec.describe Projects::DeleteService, "ResourceAllocation schedules", type: :model do
  shared_let(:admin) { create(:admin) }

  let(:project) { create(:project) }
  let(:subproject) { create(:project, parent: project) }
  let(:other_project) { create(:project) }
  let(:principal) { create(:user) }
  let(:other_principal) { create(:user) }
  let(:schedule_service) { instance_spy(ResourceAllocations::UpdateScheduleService) }

  subject(:delete) { described_class.new(user: admin, model: project.reload).call }

  before do
    work_package = create(:work_package, project:)
    create(:resource_allocation, entity: work_package, principal:,
                                 start_date: Date.new(2026, 1, 12), end_date: Date.new(2026, 1, 16))
    create(:resource_allocation, entity: create(:work_package, project:, parent: work_package), principal:)
    create(:resource_allocation, entity: create(:work_package, project: subproject), principal: other_principal,
                                 start_date: Date.new(2026, 1, 7))
    create(:resource_allocation, entity: work_package, principal: other_principal, state: "canceled",
                                 start_date: Date.new(2026, 1, 1))
    create(:resource_allocation, entity: create(:work_package, project: other_project), principal: other_principal,
                                 start_date: Date.new(2026, 1, 2))

    allow(ResourceAllocations::UpdateScheduleService).to receive(:new).and_return(schedule_service)
  end

  it "recomputes each principal once, from the earliest start of their deleted allocations" do
    expect(delete).to be_success

    expect(schedule_service).to have_received(:call).twice
    expect(schedule_service).to have_received(:call).with(users: [principal], from: Date.new(2026, 1, 5))
    expect(schedule_service).to have_received(:call).with(users: [other_principal], from: Date.new(2026, 1, 7))
  end
end
