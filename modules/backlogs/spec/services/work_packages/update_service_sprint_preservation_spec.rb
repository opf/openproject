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

RSpec.describe WorkPackages::UpdateService, "sprint preservation on project change", type: :model do
  let(:source_sharing) { "no_sharing" }
  let(:target_sharing) { "receive_shared" }
  let(:source_project) { create(:project, name: "Source project", public: true, sprint_sharing: source_sharing) }
  let(:target_project) { create(:project, name: "Target project", public: true, sprint_sharing: target_sharing) }

  let(:project_permissions) do
    %i[edit_work_packages
       edit_project
       add_work_packages
       move_work_packages
       view_project
       view_sprints
       view_work_packages
       manage_sprint_items]
  end

  let(:source_project_permissions) { project_permissions }
  let(:target_project_permissions) { source_project_permissions }

  let(:user) do
    create(:user, member_with_permissions: {
             source_project => source_project_permissions,
             target_project => target_project_permissions
           })
  end

  let(:sprint_in_source_project) do
    create(:sprint,
           project: source_project,
           name: "Sprint 1",
           start_date: Time.zone.today,
           finish_date: Time.zone.today + 14.days)
  end

  let(:work_package) do
    create(:work_package,
           project: source_project,
           author: user,
           sprint: sprint_in_source_project)
  end

  let(:instance) { described_class.new(user:, model: work_package) }

  current_user { user }

  describe "when changing the project" do
    context "when the work package has a sprint" do
      context "when moving to a project that does NOT have access to the sprint" do
        it "nullifies the sprint_id" do
          result = instance.call(project: target_project)

          expect(result).to be_success
          expect(work_package.reload.sprint_id).to be_nil
          expect(work_package.project).to eq(target_project)
        end
      end

      context "when moving to a project that HAS access to the sprint" do
        let(:source_sharing) { "share_all_projects" }

        it "preserves the sprint_id" do
          result = instance.call(project: target_project)

          expect(result).to be_success
          expect(work_package.reload.sprint_id).to eq(sprint_in_source_project.id)
          expect(work_package.project).to eq(target_project)
        end

        context "with the manage_sprint_items permission missing" do
          let(:source_project_permissions) { project_permissions - %i[manage_sprint_items] }
          let(:target_project_permissions) { project_permissions - %i[manage_sprint_items] }

          # Usually this should not work without the permission, but since the change is
          # performed via `change_by_system`, this is bypassed.
          it "preserves the sprint_id" do
            result = instance.call(project: target_project)

            expect(result).to be_success
            expect(work_package.reload.sprint_id).to eq(sprint_in_source_project.id)
            expect(work_package.project).to eq(target_project)
          end
        end
      end

      context "when the work package project is NOT changing" do
        it "preserves the sprint_id" do
          original_sprint_id = work_package.sprint_id
          result = instance.call(subject: "Updated Subject")

          expect(result).to be_success
          expect(work_package.reload.sprint_id).to eq(original_sprint_id)
        end
      end
    end

    context "when the work package does NOT have a sprint" do
      let(:work_package_without_sprint) do
        create(:work_package,
               subject: "Work Package Without Sprint",
               project: source_project,
               sprint: nil)
      end

      let(:instance) { described_class.new(user:, model: work_package_without_sprint) }

      it "keeps sprint_id nil when moving to another project" do
        result = instance.call(project: target_project)

        expect(result).to be_success
        expect(work_package_without_sprint.reload.sprint_id).to be_nil
        expect(work_package_without_sprint.project).to eq(target_project)
      end
    end
  end

  describe "Integration with sprint visibility logic" do
    context "when sprint is owned by the target project" do
      let(:sprint_in_target_project) do
        create(:sprint,
               project: target_project,
               name: "Target Sprint",
               start_date: Time.zone.today,
               finish_date: Time.zone.today + 14.days)
      end

      let(:work_package) do
        create(:work_package,
               subject: "Work Package",
               project: source_project,
               sprint: sprint_in_target_project)
      end

      let(:target_sharing) { "share_all_projects" }
      let(:source_sharing) { "receive_shared" }

      it "preserves the sprint when moving to the owning project" do
        result = instance.call(project: target_project)

        expect(result).to be_success
        expect(work_package.reload.sprint_id).to eq(sprint_in_target_project.id)
      end
    end

    context "when sprint is shared with the target project" do
      let(:work_package) do
        create(:work_package,
               subject: "Work Package",
               project: source_project,
               sprint: sprint_in_source_project)
      end

      let(:source_sharing) { "share_all_projects" }

      it "preserves the sprint when moving to a project that receives the sprint" do
        result = instance.call(project: target_project)

        expect(result).to be_success
        expect(work_package.reload.sprint_id).to eq(sprint_in_source_project.id)
      end
    end

    context "when sprint is NOT shared with the target project" do
      let(:work_package) do
        create(:work_package,
               subject: "Work Package",
               project: source_project,
               sprint: sprint_in_source_project)
      end

      it "nullifies the sprint when moving to a project that cannot access the sprint" do
        result = instance.call(project: target_project)

        expect(result).to be_success
        expect(work_package.reload.sprint_id).to be_nil
      end
    end
  end
end
