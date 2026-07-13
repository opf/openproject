# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Work package resource",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false, enabled_module_names: %w[work_package_tracking backlogs]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[work_package_tracking backlogs]) }
  shared_let(:type) { project.types.first }
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:completed_sprint) { create(:sprint, project:, status: :completed) }
  shared_let(:outside_sprint) { create(:sprint, project: other_project) }
  shared_let(:work_package) { create(:work_package, project:, type:, status:, priority:) }

  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[edit_work_packages view_work_packages manage_sprint_items view_sprints] }
  let(:other_role) { create(:project_role, permissions: other_permissions) }
  let(:other_permissions) { permissions }

  current_user do
    create(:user, member_with_roles: { project => role, other_project => other_role })
  end

  describe "PATCH /api/v3/work_packages/:id" do
    let(:path) { api_v3_paths.work_package(work_package.id) }
    let(:parameters) do
      {
        storyPoints: 5,
        lockVersion: work_package.lock_version,
        _links: {
          sprint: {
            href: api_v3_paths.sprint(sprint.id)
          }
        }
      }
    end

    before do
      patch path, parameters.to_json
    end

    it_behaves_like "successful response", 200, "WorkPackage"

    it "applies the given parameters" do
      expect(WorkPackage.first.attributes.slice("sprint_id", "story_points", "position"))
        .to eq(
          {
            "sprint_id" => sprint.id,
            "story_points" => 5,
            "position" => 1
          }
        )
    end

    context "when the user does not have permission to manage sprint items" do
      let(:permissions) { %i[edit_work_packages view_work_packages view_sprints] }

      it_behaves_like "read-only violation", "sprint", WorkPackage
    end

    context "when the user does not have permission to view sprints" do
      let(:permissions) { %i[edit_work_packages view_work_packages manage_sprint_items] }

      it_behaves_like "constraint violation" do
        let(:message) { "Sprint is not assignable since it is either not shared with the project or already finished." }
      end
    end

    context "when the user has only the permission to manage sprint items/view sprints and changes only the sprint" do
      let(:permissions) { %i[view_work_packages manage_sprint_items view_sprints] }

      let(:parameters) do
        {
          lockVersion: work_package.lock_version,
          _links: {
            sprint: {
              href: api_v3_paths.sprint(sprint.id)
            }
          }
        }
      end

      it_behaves_like "successful response", 200, "WorkPackage"

      it "applies the given parameters" do
        expect(WorkPackage.first.sprint)
          .to eq(sprint)
      end
    end

    context "when the user has only the permission to manage sprint items/view sprints and changes more than the sprint" do
      let(:permissions) { %i[view_work_packages manage_sprint_items view_sprints] }

      let(:parameters) do
        {
          lockVersion: work_package.lock_version,
          subject: "abc",
          _links: {
            sprint: {
              href: api_v3_paths.sprint(sprint.id)
            }
          }
        }
      end

      it_behaves_like "read-only violation", "subject", WorkPackage
    end

    context "when attempting to assign the work package to a completed sprint" do
      let(:parameters) do
        {
          storyPoints: 5,
          lockVersion: work_package.lock_version,
          _links: {
            sprint: {
              href: api_v3_paths.sprint(completed_sprint.id)
            }
          }
        }
      end

      it_behaves_like "constraint violation" do
        let(:message) { "Sprint is not assignable since it is either not shared with the project or already finished." }
      end
    end

    context "when attempting to assign the work package to a non valid sprint" do
      let(:other_permissions) { [] }
      let(:parameters) do
        {
          storyPoints: 5,
          lockVersion: work_package.lock_version,
          _links: {
            sprint: {
              href: api_v3_paths.sprint(outside_sprint.id)
            }
          }
        }
      end

      it_behaves_like "constraint violation" do
        let(:message) { "Sprint is not assignable since it is either not shared with the project or already finished." }
      end
    end
  end
end
