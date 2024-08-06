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

RSpec.describe WorkPackage do
  describe "Story positions" do
    def build_work_package(options)
      build(:work_package, options.reverse_merge(version_id: sprint_1.id,
                                                 priority_id: priority.id,
                                                 project_id: project.id,
                                                 status_id: status.id,
                                                 type_id: story_type.id))
    end

    def create_work_package(options)
      build_work_package(options).tap(&:save!)
    end

    let(:status)   { create(:status) }
    let(:priority) { create(:priority_normal) }
    let(:project)  { create(:project)         }

    let(:story_type) { create(:type, name: "Story")    }
    let(:epic_type)  { create(:type, name: "Epic")     }
    let(:task_type)  { create(:type, name: "Task")     }
    let(:other_type) { create(:type, name: "Feedback") }

    let(:sprint_1) { create(:version, project_id: project.id, name: "Sprint 1") }
    let(:sprint_2) { create(:version, project_id: project.id, name: "Sprint 2") }

    let(:work_package_1) { create_work_package(subject: "WorkPackage 1", version_id: sprint_1.id) }
    let(:work_package_2) { create_work_package(subject: "WorkPackage 2", version_id: sprint_1.id) }
    let(:work_package_3) { create_work_package(subject: "WorkPackage 3", version_id: sprint_1.id) }
    let(:work_package_4) { create_work_package(subject: "WorkPackage 4", version_id: sprint_1.id) }
    let(:work_package_5) { create_work_package(subject: "WorkPackage 5", version_id: sprint_1.id) }

    let(:work_package_a) { create_work_package(subject: "WorkPackage a", version_id: sprint_2.id) }
    let(:work_package_b) { create_work_package(subject: "WorkPackage b", version_id: sprint_2.id) }
    let(:work_package_c) { create_work_package(subject: "WorkPackage c", version_id: sprint_2.id) }

    let(:feedback_1) do
      create_work_package(subject: "Feedback 1", version_id: sprint_1.id,
                          type_id: other_type.id)
    end

    let(:task_1) do
      create_work_package(subject: "Task 1", version_id: sprint_1.id,
                          type_id: task_type.id)
    end

    before do
      # We had problems while writing these specs, that some elements kept
      # creaping around between tests. This should be fast enough to not harm
      # anybody while adding an additional safety net to make sure, that
      # everything runs in isolation.
      WorkPackage.delete_all
      IssuePriority.delete_all
      Status.delete_all
      Project.delete_all
      Type.delete_all
      Version.delete_all

      # Enable and configure backlogs
      project.enabled_module_names = project.enabled_module_names + ["backlogs"]
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [story_type.id, epic_type.id],
                                                                           "task_type" => task_type.id })

      # Otherwise the type id's from the previous test are still active
      WorkPackage.instance_variable_set(:@backlogs_types, nil)

      project.types = [story_type, epic_type, task_type, other_type]
      sprint_1
      sprint_2

      # Create and order work_packages
      work_package_1.move_to_bottom
      work_package_2.move_to_bottom
      work_package_3.move_to_bottom
      work_package_4.move_to_bottom
      work_package_5.move_to_bottom

      work_package_a.move_to_bottom
      work_package_b.move_to_bottom
      work_package_c.move_to_bottom
    end

    describe "- Creating a work_package in a sprint" do
      it "adds it to the bottom of the list" do
        new_work_package = create_work_package(subject: "Newest WorkPackage", version_id: sprint_1.id)

        expect(new_work_package).not_to be_new_record
        expect(new_work_package).to be_last
      end

      it "does not reorder the existing work_packages" do
        new_work_package = create_work_package(subject: "Newest WorkPackage", version_id: sprint_1.id)

        expect([work_package_1, work_package_2, work_package_3, work_package_4,
                work_package_5].each(&:reload).map(&:position)).to eq([1, 2, 3, 4, 5])
      end
    end

    describe "- Removing a work_package from the sprint" do
      it "reorders the remaining work_packages" do
        work_package_2.version = sprint_2
        work_package_2.save!

        expect(sprint_1.work_packages.order(Arel.sql("id"))).to eq([work_package_1, work_package_3, work_package_4,
                                                                    work_package_5])
        expect(sprint_1.work_packages.order(Arel.sql("id")).each(&:reload).map(&:position)).to eq([1, 2, 3, 4])
      end
    end

    describe "- Adding a work_package to a sprint" do
      it "adds it to the bottom of the list" do
        work_package_a.version = sprint_1
        work_package_a.save!

        expect(work_package_a).to be_last
      end

      it "does not reorder the existing work_packages" do
        work_package_a.version = sprint_1
        work_package_a.save!

        expect([work_package_1, work_package_2, work_package_3, work_package_4,
                work_package_5].each(&:reload).map(&:position)).to eq([1, 2, 3, 4, 5])
      end
    end

    describe "- Deleting a work_package in a sprint" do
      it "reorders the existing work_packages" do
        work_package_3.destroy

        expect([work_package_1, work_package_2, work_package_4,
                work_package_5].each(&:reload).map(&:position)).to eq([1, 2, 3, 4])
      end
    end

    describe "- Changing the type" do
      describe "by moving a story to another story type" do
        it "keeps all positions in the sprint in tact" do
          work_package_3.type = epic_type
          work_package_3.save!

          expect([work_package_1, work_package_2, work_package_3, work_package_4,
                  work_package_5].each(&:reload).map(&:position)).to eq([1, 2, 3, 4, 5])
        end
      end

      describe "by moving a story to a non-backlogs type" do
        it "removes it from any list" do
          work_package_3.type = other_type
          work_package_3.save!

          expect(work_package_3).not_to be_in_list
        end

        it "reorders the remaining stories" do
          work_package_3.type = other_type
          work_package_3.save!

          expect([work_package_1, work_package_2, work_package_4,
                  work_package_5].each(&:reload).map(&:position)).to eq([1, 2, 3, 4])
        end
      end

      describe "by moving a story to the task type" do
        it "removes it from any list" do
          work_package_3.type = task_type
          work_package_3.save!

          expect(work_package_3).not_to be_in_list
        end

        it "reorders the remaining stories" do
          work_package_3.type = task_type
          work_package_3.save!

          expect([work_package_1, work_package_2, work_package_4,
                  work_package_5].each(&:reload).map(&:position)).to eq([1, 2, 3, 4])
        end
      end

      describe "by moving a task to the story type" do
        it "adds it to the bottom of the list" do
          task_1.type = story_type
          task_1.save!

          expect(task_1).to be_last
        end

        it "does not reorder the existing stories" do
          task_1.type = story_type
          task_1.save!

          expect([work_package_1, work_package_2, work_package_3, work_package_4, work_package_5,
                  task_1].each(&:reload).map(&:position)).to eq([1, 2, 3, 4, 5, 6])
        end
      end

      describe "by moving a non-backlogs work_package to a story type" do
        it "adds it to the bottom of the list" do
          feedback_1.type = story_type
          feedback_1.save!

          expect(feedback_1).to be_last
        end

        it "does not reorder the existing stories" do
          feedback_1.type = story_type
          feedback_1.save!

          expect([work_package_1, work_package_2, work_package_3, work_package_4, work_package_5,
                  feedback_1].each(&:reload).map(&:position)).to eq([1, 2, 3, 4, 5, 6])
        end
      end
    end

    describe "- Moving work_packages between projects" do
      # N.B.: You cannot move a ticket to another project and change the
      # 'version' at the same time. On the other hand, OpenProject tries
      # to keep the 'version' if possible (e.g. within project
      # hierarchies with shared versions)

      let(:project_wo_backlogs) { create(:project) }
      let(:sub_project_wo_backlogs) { create(:project) }

      let(:shared_sprint) do
        create(:version,
               project_id: project.id,
               name: "Shared Sprint",
               sharing: "descendants")
      end

      let(:version_go_live) do
        create(:version,
               project_id: project_wo_backlogs.id,
               name: "Go-Live")
      end

      shared_let(:admin) { create(:admin) }

      def move_to_project(work_package, project)
        WorkPackages::UpdateService
          .new(model: work_package, user: admin)
          .call(project:)
      end

      before do
        project_wo_backlogs.enabled_module_names = project_wo_backlogs.enabled_module_names - ["backlogs"]
        sub_project_wo_backlogs.enabled_module_names = sub_project_wo_backlogs.enabled_module_names - ["backlogs"]

        project_wo_backlogs.types = [story_type, task_type, other_type]
        sub_project_wo_backlogs.types = [story_type, task_type, other_type]

        sub_project_wo_backlogs.move_to_child_of(project)

        shared_sprint
        version_go_live
      end

      describe "- Moving an work_package from a project without backlogs to a backlogs_enabled project" do
        describe "if the version may not be kept" do
          let(:work_package_i) do
            create_work_package(subject: "WorkPackage I",
                                version_id: version_go_live.id,
                                project_id: project_wo_backlogs.id)
          end

          before do
            work_package_i
          end

          it "sets the version_id to nil" do
            result = move_to_project(work_package_i, project)

            expect(result).to be_truthy

            expect(work_package_i.version).to be_nil
          end

          it "removes it from any list" do
            result = move_to_project(work_package_i, project)

            expect(result).to be_truthy

            expect(work_package_i).not_to be_in_list
          end
        end

        describe "if the version may be kept" do
          let(:work_package_i) do
            create_work_package(subject: "WorkPackage I",
                                version_id: shared_sprint.id,
                                project_id: sub_project_wo_backlogs.id)
          end

          before do
            work_package_i
          end

          it "keeps the version_id" do
            result = move_to_project(work_package_i, project)

            expect(result).to be_truthy

            expect(work_package_i.version).to eq(shared_sprint)
          end

          it "adds it to the bottom of the list" do
            result = move_to_project(work_package_i, project)

            expect(result).to be_truthy

            expect(work_package_i).to be_first
          end
        end
      end

      describe "- Moving an work_package away from backlogs_enabled project to a project without backlogs" do
        describe "if the version may not be kept" do
          it "sets the version_id to nil" do
            result = move_to_project(work_package_3, project_wo_backlogs)

            expect(result).to be_truthy

            expect(work_package_3.version).to be_nil
          end

          it "removes it from any list" do
            result = move_to_project(work_package_3, sub_project_wo_backlogs)

            expect(result).to be_truthy

            expect(work_package_3).not_to be_in_list
          end

          it "reorders the remaining work_packages" do
            result = move_to_project(work_package_3, sub_project_wo_backlogs)

            expect(result).to be_truthy

            expect([work_package_1, work_package_2, work_package_4,
                    work_package_5].each(&:reload).map(&:position)).to eq([1, 2, 3, 4])
          end
        end

        describe "if the version may be kept" do
          let(:work_package_i)   do
            create_work_package(subject: "WorkPackage I",
                                version_id: shared_sprint.id)
          end
          let(:work_package_ii) do
            create_work_package(subject: "WorkPackage II",
                                version_id: shared_sprint.id)
          end
          let(:work_package_iii) do
            create_work_package(subject: "WorkPackage III",
                                version_id: shared_sprint.id)
          end

          before do
            work_package_i.move_to_bottom
            work_package_ii.move_to_bottom
            work_package_iii.move_to_bottom

            expect([work_package_i, work_package_ii, work_package_iii].map(&:position)).to eq([1, 2, 3])
          end

          it "keeps the version_id" do
            result = move_to_project(work_package_ii, sub_project_wo_backlogs)

            expect(result).to be_truthy

            expect(work_package_ii.version).to eq(shared_sprint)
          end

          it "removes it from any list" do
            result = move_to_project(work_package_ii, sub_project_wo_backlogs)

            expect(result).to be_truthy

            expect(work_package_ii).not_to be_in_list
          end

          it "reorders the remaining work_packages" do
            result = move_to_project(work_package_ii, sub_project_wo_backlogs)

            expect(result).to be_truthy

            expect([work_package_i, work_package_iii].each(&:reload).map(&:position)).to eq([1, 2])
          end
        end
      end
    end
  end
end
