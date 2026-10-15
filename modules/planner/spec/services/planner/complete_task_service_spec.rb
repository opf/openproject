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

RSpec.describe Planner::CompleteTaskService do
  let!(:task_type) { create(:type_task) }
  let!(:open_status) { create(:default_status) }
  let!(:closed_status) { create(:closed_status) }
  let!(:priority) { create(:default_priority) }
  let!(:role) do
    create(:project_role,
           permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR +
             %i[view_work_packages add_work_packages edit_work_packages])
  end
  let!(:workflows) do
    [[open_status, closed_status], [closed_status, open_status]].each do |old_status, new_status|
      create(:status_transition, type: task_type, role:, old_status:, new_status:)
    end
  end
  let(:user) { create(:user) }
  let(:planner_project) { Planner::ProjectService.new(user).call.result }
  let(:task) { Planner::CreateTaskService.new(user:, project: planner_project).call(subject: "Book train", day_part: :evening).result }
  let(:done) { true }

  subject { described_class.new(user:, work_package: task).call(done:) }

  it "closes the task" do
    expect(subject).to be_success, -> { subject.message }
    expect(task.reload.status).to eq(closed_status)
  end

  context "when reopening a closed task" do
    let(:done) { false }

    before { described_class.new(user:, work_package: task).call(done: true) }

    it "moves it back to the default status" do
      expect(subject).to be_success, -> { subject.message }
      expect(task.reload.status).to eq(open_status)
    end
  end

  context "when the workflow does not allow closing" do
    let!(:workflows) { nil }

    it "fails with a message" do
      expect(subject).to be_failure
      expect(subject.message).to eq(I18n.t("planner.errors.cannot_close"))
      expect(task.reload.status).to eq(open_status)
    end
  end
end
