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

RSpec.describe Sprints::Scopes::Visible do
  shared_let(:project_globally_sharing) { create(:project, sprint_sharing: "share_all_projects") }
  shared_let(:project_receiving) { create(:project, sprint_sharing: "receive_shared") }
  shared_let(:sprint_in_global_sharer) { create(:sprint, project: project_globally_sharing) }

  shared_let(:project_with_own_sprint) { create(:project) }
  shared_let(:sprint_own) { create(:sprint, project: project_with_own_sprint) }

  shared_let(:project_with_referenced_by_wp_sprint) { create(:project) }
  shared_let(:sprint_referenced_by_wp) do
    create(:sprint, project: create(:project)) do |sprint|
      create(:work_package, sprint:, project: project_with_referenced_by_wp_sprint)
    end
  end

  shared_let(:role) { create(:project_role, permissions: [:view_sprints]) }

  shared_let(:user_with_permission_in_project_with_own_sprint) do
    create(:user) do |u|
      create(:member, project: project_with_own_sprint, user: u, roles: [role])
    end
  end
  shared_let(:user_with_permission_in_project_with_sprint_referenced_by_wp) do
    create(:user) do |u|
      create(:member, project: project_with_referenced_by_wp_sprint, user: u, roles: [role])
    end
  end
  shared_let(:user_with_permission_in_receiving_project) do
    create(:user) do |u|
      create(:member, project: project_receiving, user: u, roles: [role])
    end
  end
  shared_let(:user_with_permission_in_all_projects) do
    create(:user) do |u|
      [project_with_own_sprint,
       project_receiving,
       project_with_referenced_by_wp_sprint].each do |project|
        create(:member, project:, user: u, roles: [role])
      end
    end
  end
  shared_let(:user_without_permission) do
    create(:user) do |u|
      [project_with_own_sprint,
       project_receiving,
       project_with_referenced_by_wp_sprint].each do |project|
        create(:member,
               project:,
               user: u,
               roles: [create(:project_role, permissions: [:view_work_packages])])
      end
    end
  end
  shared_let(:user_without_membership) { create(:user) }

  subject { Sprint.visible(current_user) }

  context "for a user with view_sprints in project with own sprint" do
    current_user { user_with_permission_in_project_with_own_sprint }

    it "returns all sprints in that project" do
      expect(subject).to contain_exactly(sprint_own)
    end
  end

  context "for a user with view_sprints in project sprint referenced by wp" do
    current_user { user_with_permission_in_project_with_sprint_referenced_by_wp }

    it "returns all sprints in that project" do
      expect(subject).to contain_exactly(sprint_referenced_by_wp)
    end
  end

  context "for a user with view_sprints in project receiving sprints" do
    current_user { user_with_permission_in_receiving_project }

    it "returns all sprints in that project" do
      expect(subject).to contain_exactly(sprint_in_global_sharer)
    end
  end

  context "for a user with view_sprints in all projects" do
    current_user { user_with_permission_in_all_projects }

    it "returns sprints from all projects including shared ones" do
      expect(subject).to contain_exactly(sprint_own,
                                         sprint_referenced_by_wp,
                                         sprint_in_global_sharer)
    end
  end

  context "for a user with a different permission but not view_sprints" do
    current_user { user_without_permission }

    it "returns no sprints" do
      expect(subject).to be_empty
    end
  end

  context "for a user without any membership" do
    current_user { user_without_membership }

    it "returns no sprints" do
      expect(subject).to be_empty
    end
  end

  context "when called without a user argument" do
    current_user { user_with_permission_in_all_projects }

    it "uses User.current to return sprints from all projects including shared ones" do
      expect(subject).to contain_exactly(sprint_own,
                                         sprint_referenced_by_wp,
                                         sprint_in_global_sharer)
    end
  end
end
