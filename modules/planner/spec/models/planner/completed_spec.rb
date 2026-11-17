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

RSpec.describe Planner::Completed do
  let!(:task) { create(:type_task) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:user) { create(:user) }
  let(:project) { Planner::ProjectService.new(user).call.result }
  let(:closed) { create(:closed_status) }

  let!(:done_yesterday) { create(:work_package, project:, type: task, status: closed, updated_at: 1.day.ago) }
  let!(:done_today) { create(:work_package, project:, type: task, status: closed, updated_at: 1.hour.ago) }
  let!(:done_long_ago) { create(:work_package, project:, type: task, status: closed, updated_at: 30.days.ago) }
  let!(:open_task) { create(:work_package, project:, type: task, updated_at: 1.hour.ago) }

  subject(:completed) { described_class.new(user:, project:) }

  around { |example| travel_to(Time.zone.parse("2026-10-08 12:00")) { example.run } }

  it "groups the tasks completed in the last days by day, newest first" do
    expect(completed.days.map(&:date)).to eq([Date.new(2026, 10, 8), Date.new(2026, 10, 7)])
    expect(completed.days.map(&:work_packages)).to eq([[done_today], [done_yesterday]])
  end
end
