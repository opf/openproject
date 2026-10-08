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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Planner::Overdue do
  let!(:task) { create(:type_task) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:user) { create(:user) }
  let(:project) { Planner::ProjectService.new(user).call.result }

  let!(:left_over) do
    create(:work_package, project:, type: task, subject: "Left over", due_date: Date.new(2026, 10, 2))
  end
  let!(:undated) { create(:work_package, project:, type: task, subject: "Someday") }
  let!(:done_earlier) do
    create(:work_package, project:, type: task, subject: "Done", due_date: Date.new(2026, 10, 5),
                          status: create(:closed_status))
  end
  let!(:for_today) { create(:work_package, project:, type: task, subject: "Today", due_date: Date.new(2026, 10, 6)) }
  let!(:for_tomorrow) do
    create(:work_package, project:, type: task, subject: "Tomorrow", due_date: Date.new(2026, 10, 7))
  end

  subject(:overdue) { described_class.new(user:, project:) }

  around { |example| travel_to(Time.zone.parse("2026-10-06 08:00")) { example.run } }

  it "holds open tasks left over from earlier days, then those without a date" do
    expect(overdue.work_packages).to eq([left_over, undated])
    expect(overdue.count).to eq(2)
  end
end
