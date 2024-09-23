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

RSpec.describe WorkPackages::UpdateService, "version inheritance", type: :model do
  let(:type_feature) { build(:type_feature) }
  let(:type_task) { build(:type_task) }
  let(:type_bug) { build(:type_bug) }
  let(:version1) { project.versions.first }
  let(:version2) { project.versions.last }
  let(:role) { build(:project_role) }
  let(:user) { build(:admin) }
  let(:issue_priority) { build(:priority) }
  let(:status) { build(:status, name: "status 1", is_default: true) }

  let(:project) do
    p = build(:project,
              members: [build(:member,
                              principal: user,
                              roles: [role])],
              types: [type_feature, type_task, type_bug])

    p.versions << build(:version, name: "Version1", project: p)
    p.versions << build(:version, name: "Version2", project: p)

    p
  end

  let(:story) do
    story = build(:work_package,
                  subject: "Story",
                  project:,
                  type: type_feature,
                  version: version1,
                  status:,
                  author: user,
                  priority: issue_priority)
    story
  end

  let(:story2) do
    story = build(:work_package,
                  subject: "Story2",
                  project:,
                  type: type_feature,
                  version: version1,
                  status:,
                  author: user,
                  priority: issue_priority)
    story
  end

  let(:story3) do
    story = build(:work_package,
                  subject: "Story3",
                  project:,
                  type: type_feature,
                  version: version1,
                  status:,
                  author: user,
                  priority: issue_priority)
    story
  end

  let(:task) do
    build(:work_package,
          subject: "Task",
          type: type_task,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:task2) do
    build(:work_package,
          subject: "Task2",
          type: type_task,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:task3) do
    build(:work_package,
          subject: "Task3",
          type: type_task,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:task4) do
    build(:work_package,
          subject: "Task4",
          type: type_task,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:task5) do
    build(:work_package,
          subject: "Task5",
          type: type_task,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:task6) do
    build(:work_package,
          subject: "Task6",
          type: type_task,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:bug) do
    build(:work_package,
          subject: "Bug",
          type: type_bug,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:bug2) do
    build(:work_package,
          subject: "Bug2",
          type: type_bug,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  let(:bug3) do
    build(:work_package,
          subject: "Bug3",
          type: type_bug,
          version: version1,
          project:,
          status:,
          author: user,
          priority: issue_priority)
  end

  before do
    project.save!

    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "points_burn_direction" => "down",
                                                                         "wiki_template" => "",
                                                                         "story_types" => [type_feature.id],
                                                                         "task_type" => type_task.id.to_s })
  end

  def standard_child_layout
    # Layout is
    # child
    # -> task3
    # -> task4
    # -> bug3
    #   -> task5
    # -> story3
    #   -> task6
    task3.parent_id = child.id
    task3.save!
    task4.parent_id = child.id
    task4.save!
    bug3.parent_id = child.id
    bug3.save!
    story3.parent_id = child.id
    story3.save!

    task5.parent_id = bug3.id
    task5.save!
    task6.parent_id = story3.id
    task6.save!

    child.reload
  end

  describe "WHEN changing version" do
    let(:instance) { described_class.new(user:, model: parent) }

    shared_examples_for "changing parent's version changes child's version" do
      it "changes the child's version to the parent's version" do
        parent.save!
        child.parent_id = parent.id
        child.save!

        standard_child_layout

        parent.reload

        call = instance.call(version: version2)

        expect(call).to be_success

        # Because of performance, these assertions are all in one it statement
        expect(child.reload.version).to eql version2
        expect(task3.reload.version).to eql version2
        expect(task4.reload.version).to eql version2
        expect(bug3.reload.version).to eql version1
        expect(story3.reload.version).to eql version1
        expect(task5.reload.version).to eql version1
        expect(task6.reload.version).to eql version1
      end
    end

    shared_examples_for "changing parent's version does not change child's version" do
      it "keeps the child's version" do
        parent.save!
        child.parent_id = parent.id
        child.save!

        standard_child_layout

        parent.reload

        instance.call(version: version2)

        # Because of performance, these assertions are all in one it statement
        expect(child.reload.version).to eql version1
        expect(task3.reload.version).to eql version1
        expect(task4.reload.version).to eql version1
        expect(bug3.reload.version).to eql version1
        expect(story3.reload.version).to eql version1
        expect(task5.reload.version).to eql version1
        expect(task6.reload.version).to eql version1
      end
    end

    describe "WITH backlogs enabled" do
      before do
        project.enabled_module_names += ["backlogs"]
      end

      describe "WITH a story" do
        let(:parent) { story }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing parent's version changes child's version"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a story as a child" do
          let(:child) { story2 }

          it_behaves_like "changing parent's version does not change child's version"
        end
      end

      describe "WITH a task (impediment) without a parent" do
        let(:parent) { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing parent's version changes child's version"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug }

          it_behaves_like "changing parent's version does not change child's version"
        end
      end

      describe "WITH a non backlogs work_package" do
        let(:parent) { bug }

        describe "WITH a task as child" do
          let(:child) { task }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a story as a child" do
          let(:child) { story }

          it_behaves_like "changing parent's version does not change child's version"
        end
      end
    end

    describe "WITH backlogs disabled" do
      before do
        project.enabled_module_names = project.enabled_module_names.find_all { |n| n != "backlogs" }
      end

      describe "WITH a story" do
        let(:parent) { story }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a story as a child" do
          let(:child) { story2 }

          it_behaves_like "changing parent's version does not change child's version"
        end
      end

      describe "WITH a task" do
        before do
          bug2.save!
          task.parent_id = bug2.id # so that it is considered a task
          task.save!
        end

        let(:parent) { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug }

          it_behaves_like "changing parent's version does not change child's version"
        end
      end

      describe "WITH a task (impediment) without a parent" do
        let(:parent) { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug }

          it_behaves_like "changing parent's version does not change child's version"
        end
      end

      describe "WITH a non backlogs work_package" do
        let(:parent) { bug }

        describe "WITH a task as child" do
          let(:child) { task }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing parent's version does not change child's version"
        end

        describe "WITH a story as a child" do
          let(:child) { story }

          it_behaves_like "changing parent's version does not change child's version"
        end
      end
    end
  end

  describe "WHEN changing the parent_id" do
    let(:instance) { described_class.new(user:, model: child) }

    shared_examples_for "changing the child's parent_issue to the parent changes child's version" do
      it "changes the child's version to the parent's version" do
        child.save!
        standard_child_layout

        parent.version = version2
        parent.save!

        instance.call(parent_id: parent.id)

        # Because of performance, these assertions are all in one it statement
        expect(child.reload.version).to eql version2
        expect(task3.reload.version).to eql version2
        expect(task4.reload.version).to eql version2
        expect(bug3.reload.version).to eql version1
        expect(story3.reload.version).to eql version1
        expect(task5.reload.version).to eql version1
        expect(task6.reload.version).to eql version1
      end
    end

    shared_examples_for "changing the child's parent to the parent leaves child's version" do
      it "keeps the child's version" do
        child.save!
        standard_child_layout

        parent.version = version2
        parent.save!

        instance.call(parent_id: parent.id)

        # Because of performance, these assertions are all in one it statement
        expect(child.reload.version).to eql version1
        expect(task3.reload.version).to eql version1
        expect(task4.reload.version).to eql version1
        expect(bug3.reload.version).to eql version1
        expect(story3.reload.version).to eql version1
        expect(task5.reload.version).to eql version1
        expect(task6.reload.version).to eql version1
      end
    end

    describe "WITH backogs enabled" do
      before do
        story.project.enabled_module_names += ["backlogs"]
      end

      describe "WITH a story as parent" do
        let(:parent) { story }

        describe "WITH a story as child" do
          let(:child) { story2 }

          it_behaves_like "changing the child's parent to the parent leaves child's version"
        end

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing the child's parent_issue to the parent changes child's version"
        end

        describe "WITH a non-backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing the child's parent to the parent leaves child's version"
        end
      end

      describe "WITH a story as parent " \
               "WITH the story having a non backlogs work_package as parent " \
               "WITH a task as child" do
        before do
          bug2.save!
          story.parent_id = bug2.id
          story.save!
        end

        let(:parent) { story }
        let(:child) { task2 }

        it_behaves_like "changing the child's parent_issue to the parent changes child's version"
      end

      describe "WITH a task as parent" do
        before do
          story.save!
          task.parent_id = story.id
          task.save!
          story.reload
          task.reload
        end

        # Needs to be the story because it is not possible to change a task's
        # 'version_id'
        let(:parent) { story }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing the child's parent_issue to the parent changes child's version"
        end

        describe "WITH a non-backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing the child's parent to the parent leaves child's version"
        end
      end

      describe "WITH an impediment (task) as parent" do
        let(:parent) { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing the child's parent_issue to the parent changes child's version"
        end

        describe "WITH a non-backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing the child's parent to the parent leaves child's version"
        end
      end

      describe "WITH a non-backlogs work_package as parent" do
        let(:parent) { bug }

        describe "WITH a story as child" do
          let(:child) { story2 }

          it_behaves_like "changing the child's parent to the parent leaves child's version"
        end

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_behaves_like "changing the child's parent to the parent leaves child's version"
        end

        describe "WITH a non-backlogs work_package as child" do
          let(:child) { bug2 }

          it_behaves_like "changing the child's parent to the parent leaves child's version"
        end
      end
    end
  end
end
