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

  shared_let(:project) { create(:project, public: false) }
  shared_let(:type) { project.types.first }
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:completed_sprint) { create(:sprint, project:, status: :completed) }
  shared_let(:outside_sprint) { create(:sprint, project: create(:project)) }

  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[add_work_packages view_work_packages manage_sprint_items view_sprints] }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  describe "POST /api/v3/work_packages" do
    let(:path) { api_v3_paths.work_packages }
    let(:parameters) do
      {
        subject: "new work packages",
        storyPoints: 5,
        _links: {
          type: {
            href: api_v3_paths.type(type.id)
          },
          project: {
            href: api_v3_paths.project(project.id)
          },
          sprint: {
            href: api_v3_paths.sprint(sprint.id)
          }
        }
      }
    end

    before do
      post path, parameters.to_json
    end

    it_behaves_like "successful response", 201, "WorkPackage"

    it "creates a work package" do
      expect(WorkPackage.count).to eq(1)
    end

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
      let(:permissions) { %i[add_work_packages view_work_packages view_sprints] }

      it_behaves_like "read-only violation", "sprint", WorkPackage
    end

    context "when the user does not have permission to view sprints" do
      let(:permissions) { %i[add_work_packages view_work_packages manage_sprint_items] }

      it_behaves_like "constraint violation" do
        let(:message) { "Sprint is not assignable since it is either not shared with the project or already finished." }
      end
    end

    context "when attempting to create the work package on a completed sprint" do
      let(:parameters) do
        {
          subject: "new work packages",
          storyPoints: 5,
          _links: {
            type: {
              href: api_v3_paths.type(type.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            },
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

    context "when attempting to create the work package on a non valid sprint" do
      let(:parameters) do
        {
          subject: "new work packages",
          storyPoints: 5,
          _links: {
            type: {
              href: api_v3_paths.type(type.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            },
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
