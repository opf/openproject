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

RSpec.describe RecurringWorkPackages::CreateNextOnCloseService do
  shared_let(:default_status) { create(:default_status) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages edit_work_packages add_work_package_notes
                           view_recurring_work_packages manage_recurring_work_packages])
  end
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  before do
    create(:status_transition, type:, role:, old_status: default_status, new_status: closed_status)
    create(:status_transition, type:, role:, old_status: closed_status, new_status: default_status)
  end

  let(:work_package) do
    create(:work_package, project:, type:, author: user, status: default_status, start_date: Date.new(2026, 10, 5))
  end
  let!(:series) do
    RecurringWorkPackages::CreateService
      .new(user:, work_package:)
      .call(frequency: "weekly", interval: 1, start_date: Date.new(2026, 10, 5))
      .result
  end

  def change_status(work_package, status)
    perform_enqueued_jobs do
      WorkPackages::UpdateService.new(user:, model: work_package.reload).call(status:)
    end
  end

  it "creates the next occurrence when the latest occurrence closes" do
    change_status(work_package, closed_status)

    expect(series.occurrences.reload.size).to eq(2)
    expect(series.latest_occurrence.work_package).to have_attributes(status: default_status,
                                                                     author: user,
                                                                     start_date: Date.new(2026, 10, 12))
  end

  it "creates nothing for a change that does not close" do
    perform_enqueued_jobs do
      WorkPackages::UpdateService.new(user:, model: work_package).call(subject: "Renamed")
    end

    expect(series.occurrences.reload.size).to eq(1)
  end

  it "creates no second occurrence when the work package is reopened and closed again" do
    change_status(work_package, closed_status)
    change_status(work_package, default_status)
    change_status(work_package, closed_status)

    expect(series.occurrences.reload.size).to eq(2)
  end

  it "is not applicable to a transition from closed to closed" do
    changes = { "status_id" => [closed_status.id, closed_status.id] }

    expect(described_class).not_to be_applicable(work_package:, changes:)
  end
end
