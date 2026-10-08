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

RSpec.describe Planner::AddWorkPackageService do
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
  let(:work_package) { create(:work_package, project: team_project) }

  subject { described_class.new(user:).call(work_package:) }

  around { |example| travel_to(Time.zone.parse("2026-10-06 14:00")) { example.run } }

  it "adds a task referencing it to the current day part" do
    expect(subject).to be_success, -> { subject.message }
    expect(subject.message).to eq("Added to Afternoon in the Planner.")

    task = subject.result
    expect(task.subject).to eq("##{work_package.display_id}")
    expect(Planner::DayPartField.find.day_part_of(task)).to eq(:afternoon)
    expect(Relation.where(from: task, to: work_package)).to exist
  end

  context "when it is already planned for today" do
    before { described_class.new(user:).call(work_package:) }

    it "does not add it twice" do
      expect { subject }.not_to change(WorkPackage, :count)
      expect(subject).to be_success
      expect(subject.message).to eq(I18n.t("planner.already_planned"))
    end
  end
end
