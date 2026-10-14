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

RSpec.describe Planner::CreateTaskService do
  let!(:task_type) { create(:type_task) }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }
  let!(:role) do
    create(:project_role,
           permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR +
             %i[view_work_packages add_work_packages manage_work_package_relations])
  end
  let(:team_project) { create(:project) }
  let(:user) do
    create(:user, member_with_permissions: { team_project => %i[view_work_packages manage_work_package_relations] })
  end
  let(:team_work_package) { create(:work_package, project: team_project) }
  let(:hidden_work_package) { create(:work_package) }
  let(:subject_text) { "Reply to Lena about the demo slot" }
  let(:task) { subject.result }
  let(:day_part_field) { Planner::DayPartField.find }

  subject { described_class.new(user:).call(subject: subject_text, day_part: "afternoon") }

  it "creates a task in My work, due today, in the given day part" do
    expect(subject).to be_success, -> { subject.message }
    expect(task.project).to eq(Planner::ProjectService.new(user).call.result)
    expect(task.type).to eq(task_type)
    expect(task.subject).to eq(subject_text)
    expect(task.due_date).to eq(user.today)
    expect(day_part_field.day_part_of(task)).to eq(:afternoon)
  end

  context "with a date" do
    subject { described_class.new(user:).call(subject: subject_text, date: user.today + 3) }

    it "creates the task due that day, in the morning" do
      expect(subject).to be_success, -> { subject.message }
      expect(task.due_date).to eq(user.today + 3)
      expect(day_part_field.day_part_of(task)).to eq(:morning)
    end
  end

  context "with notes" do
    subject { described_class.new(user:).call(subject: subject_text, description: "Ask about **slot 2**") }

    it "keeps them as the task's description" do
      expect(subject).to be_success, -> { subject.message }
      expect(task.description).to eq("Ask about **slot 2**")
    end
  end

  context "without a date" do
    subject { described_class.new(user:).call(subject: subject_text, date: nil) }

    it "creates an undated task" do
      expect(subject).to be_success, -> { subject.message }
      expect(task.due_date).to be_nil
      expect(task.start_date).to be_nil
    end
  end

  context "when the subject references work packages" do
    let(:subject_text) do
      "Questions on ##{team_work_package.id} and ###{hidden_work_package.id}, not #99999 or C#"
    end

    it "relates the task to the visible ones" do
      expect(subject).to be_success
      expect(Relation.where(from: task).pluck(:to_id, :relation_type))
        .to contain_exactly([team_work_package.id, Relation::TYPE_RELATES])
    end
  end

  context "when the Day part field was deleted" do
    before do
      Planner::ProjectService.new(user).call
      WorkPackageCustomField.for_semantic_key(:day_part).destroy
    end

    it "still creates the task, in the morning" do
      expect(subject).to be_success, -> { subject.message }
      expect(day_part_field.day_part_of(task)).to eq(:morning)
    end
  end

  context "when the subject is blank" do
    let(:subject_text) { "   " }

    it "fails without creating a task" do
      expect(subject).to be_failure
      expect(WorkPackage.count).to eq(0)
    end
  end
end
