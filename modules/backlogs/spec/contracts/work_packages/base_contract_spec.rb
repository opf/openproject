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

RSpec.describe WorkPackages::BaseContract, type: :model do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:backlogs_types) { [type_feature, type_task, type_bug] }
  shared_let(:project) do
    create(:project, types: backlogs_types)
  end
  shared_let(:other_project) do
    create(:project, types: backlogs_types)
  end
  shared_let(:user) do
    create(:admin, member_with_roles: { project => create(:project_role),
                                        other_project => create(:project_role) })
  end

  let(:instance) { described_class.new(work_package, user) }
  let(:version1) { build_stubbed(:version, name: "Version1", project: p) }
  let(:version2) { build_stubbed(:version, name: "Version2", project: p) }

  let(:issue_priority) { build(:priority) }
  let(:status) { build_stubbed(:status, name: "status 1", is_default: true) }

  let(:story) do
    build_stubbed(:work_package,
                  subject: "Story",
                  project:,
                  type: type_feature,
                  version: version1,
                  status:,
                  author: user,
                  priority: issue_priority)
  end

  let(:story2) do
    build_stubbed(:work_package,
                  subject: "Story2",
                  project:,
                  type: type_feature,
                  version: version1,
                  status:,
                  author: user,
                  priority: issue_priority)
  end

  let(:task) do
    build_stubbed(:work_package,
                  subject: "Task",
                  type: type_task,
                  version: version1,
                  project:,
                  status:,
                  author: user,
                  priority: issue_priority)
  end

  let(:task2) do
    build_stubbed(:work_package,
                  subject: "Task2",
                  type: type_task,
                  version: version1,
                  project:,
                  status:,
                  author: user,
                  priority: issue_priority)
  end

  let(:bug) do
    build_stubbed(:work_package,
                  subject: "Bug",
                  type: type_bug,
                  version: version1,
                  project:,
                  status:,
                  author: user,
                  priority: issue_priority)
  end

  let(:bug2) do
    build_stubbed(:work_package,
                  subject: "Bug2",
                  type: type_bug,
                  version: version1,
                  project:,
                  status:,
                  author: user,
                  priority: issue_priority)
  end

  let(:relatable_scope) do
    scope = instance_double(ActiveRecord::Relation)

    allow(scope)
      .to receive_messages(where: scope,
                           empty?: false)

    scope
  end

  subject(:valid) { instance.validate }

  before do
    allow(project)
      .to receive(:assignable_versions)
      .and_return([version1, version2])
    allow(other_project)
      .to receive(:assignable_versions)
      .and_return([version1, version2])

    allow(WorkPackage)
      .to receive(:relatable)
            .and_return(relatable_scope)

    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "points_burn_direction" => "down",
                                                                         "wiki_template" => "",
                                                                         "story_types" => [type_feature.id],
                                                                         "task_type" => type_task.id.to_s })
  end

  describe "story_points" do
    let(:work_package) { task }

    it "is writable" do
      work_package.story_points = 5
      expect(subject).to be_truthy
    end
  end

  shared_examples_for "is valid" do
    it "is valid" do
      expect(subject).to be_truthy
    end
  end

  describe "version being restricted" do
    shared_examples_for "version not being restricted by the parent" do
      before do
        work_package.parent ||= parent
      end

      describe "WITHOUT a version and the parent also having no version" do
        before do
          parent.version = nil
          work_package.version = nil
        end

        include_examples "is valid"
      end

      describe "WITHOUT a version and the parent having a version" do
        before do
          parent.version = version1
          work_package.version = nil
        end

        include_examples "is valid"
      end

      describe "WITH a version and the parent having a different version" do
        before do
          parent.version = version1
          work_package.version = version2
        end

        include_examples "is valid"
      end

      describe "WITH a version and the parent having the same version" do
        before do
          parent.version = version1
          work_package.version = version1
        end

        include_examples "is valid"
      end

      describe "WITH a version and the parent having no version" do
        before do
          parent.version = nil
          work_package.version = version1
        end

        include_examples "is valid"
      end
    end

    shared_examples_for "version without restriction" do
      describe "WITHOUT a version" do
        before do
          work_package.version = nil
        end

        include_examples "is valid"
      end

      describe "WITH a version" do
        before do
          work_package.version = version1
        end

        include_examples "is valid"
      end
    end

    describe "WITH a story" do
      let(:work_package) { story }

      describe "WITHOUT a parent work_package" do
        it_behaves_like "version without restriction"
      end

      describe "WITH a story as its parent" do
        let(:parent) { story2 }

        it_behaves_like "version not being restricted by the parent"
      end

      describe "WITH a non backlogs tracked work_package as its parent" do
        let(:parent) { bug }

        it_behaves_like "version not being restricted by the parent"
      end
    end

    describe "WITH a task" do
      let(:work_package) { task }

      describe "WITHOUT a parent work_package (would then be an impediment)" do
        it_behaves_like "version without restriction"
      end

      describe "WITH a task as its parent" do
        before do
          task.parent = task2
        end

        let(:parent) { task2 }

        it_behaves_like "version not being restricted by the parent"
      end

      describe "WITH a story as its parent" do
        let(:parent) { story }

        it_behaves_like "version not being restricted by the parent"
      end

      describe "WITH a non backlogs tracked work_package as its parent" do
        let(:parent) { bug }

        it_behaves_like "version not being restricted by the parent"
      end
    end

    describe "WITH a non backlogs work_package" do
      let(:work_package) { bug }

      describe "WITHOUT a parent work_package" do
        it_behaves_like "version without restriction"
      end

      describe "WITH a task as its parent" do
        let(:parent) { task2 }

        it_behaves_like "version not being restricted by the parent"
      end

      describe "WITH a story as its parent" do
        let(:parent) { story }

        it_behaves_like "version not being restricted by the parent"
      end

      describe "WITH a non backlogs tracked work_package as its parent" do
        let(:parent) { bug2 }

        it_behaves_like "version not being restricted by the parent"
      end
    end
  end

  describe "parent has to be in same project" do
    shared_examples_for "project id unrestricted by parent" do
      describe "WITH the parent having a different project" do
        before do
          parent.project = other_project
          work_package.parent = parent
        end

        include_examples "is valid"
      end

      describe "WITH the work_package having a different project" do
        before do
          work_package.parent = parent
          work_package.project = other_project
        end

        include_examples "is valid"
      end
    end

    describe "WITH a task" do
      let(:work_package) { task }

      describe "WITH a story as its parent" do
        let(:parent) { story }

        include_examples "project id unrestricted by parent"
      end

      describe "WITH a non backlogs work package as its parent" do
        let(:parent) { bug }

        include_examples "project id unrestricted by parent"
      end
    end

    describe "WITH a story" do
      let(:work_package) { story }

      describe "WITH a story as its parent" do
        let(:parent) { story2 }

        include_examples "project id unrestricted by parent"
      end

      describe "WITH a non backlogs work package as its parent" do
        let(:parent) { bug }

        include_examples "project id unrestricted by parent"
      end
    end

    describe "WITH a non backlogs work package" do
      let(:work_package) { bug }

      describe "WITH a story as its parent" do
        let(:parent) { story }

        include_examples "project id unrestricted by parent"
      end

      describe "WITH a non backlogs work package as its parent" do
        let(:parent) { bug2 }

        include_examples "project id unrestricted by parent"
      end
    end
  end
end
