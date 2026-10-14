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

RSpec.describe Planner::ProjectService do
  let!(:task) { create(:type_task) }
  let!(:milestone) { create(:type_milestone) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:user) { create(:user) }
  let(:project) { subject.result }
  let(:day_part) { WorkPackageCustomField.for_semantic_key(:day_part) }

  subject { described_class.new(user).call }

  it "creates a private project the user is a member of" do
    expect(subject).to be_success, -> { subject.errors.full_messages.to_sentence }
    expect(project).not_to be_public
    expect(project.users).to contain_exactly(user)
    expect(Member.find_by(project:, principal: user).roles).to contain_exactly(role)
  end

  it "enables only work packages and the My work variant of the first non-milestone type" do
    expect(project.enabled_module_names).to contain_exactly("work_package_tracking")
    expect(project.project_types.map(&:type)).to contain_exactly(task)
    expect(project.project_types.first.variant).not_to be_default
  end

  it "makes the Day part field available to the project's tasks only" do
    expect(subject).to be_success
    expect(day_part.possible_values.map(&:value)).to eq(%w[Morning Afternoon Evening])

    expect(WorkPackage.new(project:, type: task).available_custom_fields).to include(day_part)
    expect(WorkPackage.new(project: create(:project, types: [task]), type: task).available_custom_fields)
      .not_to include(day_part)
  end

  it "remembers the project in the user's preferences" do
    expect(subject).to be_success
    expect(user.reload.pref.planner_project_id).to eq(project.id)
  end

  context "when the instance already has a field named Day part" do
    let!(:own_field) { create(:list_wp_custom_field, name: "Day part") }

    it "creates its own field next to it" do
      expect(subject).to be_success, -> { subject.errors.full_messages.to_sentence }
      expect(day_part).not_to eq(own_field)
      expect(day_part.name).to eq("Day part (My planner)")
    end
  end

  context "when called again" do
    let!(:first_project) { described_class.new(user).call.result }

    it "returns the same project" do
      expect { subject }.not_to change(Project, :count)
      expect(project).to eq(first_project)
    end
  end

  context "when the user left their project" do
    let!(:first_project) { described_class.new(user).call.result }

    before { Member.where(project: first_project, principal: user).destroy_all }

    it "creates a new one" do
      expect(project).not_to eq(first_project)
      expect(project.users).to contain_exactly(user)
    end
  end

  context "when another user already has a project" do
    let!(:other_project) { described_class.new(create(:user)).call.result }

    it "shares the field and variant but not the project" do
      expect { subject }
        .not_to change { [WorkPackageCustomField.count, TypeVariant.count, FormConfiguration.count] }
      expect(project).not_to eq(other_project)
      expect(project.project_types.first.variant).to eq(other_project.project_types.first.variant)
    end
  end
end
