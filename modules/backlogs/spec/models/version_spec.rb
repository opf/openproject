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

RSpec.describe Version do
  it { is_expected.to have_many :version_settings }

  describe "rebuild positions" do
    def build_work_package(options = {})
      build(:work_package, options.reverse_merge(version_id: version.id,
                                                 priority_id: priority.id,
                                                 project_id: project.id,
                                                 status_id: status.id))
    end

    def create_work_package(options = {})
      build_work_package(options).tap(&:save!)
    end

    let(:status)   { create(:status) }
    let(:priority) { create(:priority_normal) }
    let(:project)  { create(:project, name: "Project 1", types: [epic_type, story_type, task_type, other_type]) }

    let(:epic_type)  { create(:type, name: "Epic") }
    let(:story_type) { create(:type, name: "Story") }
    let(:task_type)  { create(:type, name: "Task")  }
    let(:other_type) { create(:type, name: "Other") }

    let(:version) { create(:version, project_id: project.id, name: "Version") }

    shared_let(:admin) { create(:admin) }

    def move_to_project(work_package, project)
      WorkPackages::UpdateService
        .new(model: work_package, user: admin)
        .call(project:)
    end

    before do
      # We had problems while writing these specs, that some elements kept
      # creeping around between tests. This should be fast enough to not harm
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
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [epic_type.id, story_type.id],
                                                                           "task_type" => task_type.id })

      # Otherwise the type id's from the previous test are still active
      WorkPackage.instance_variable_set(:@backlogs_types, nil)

      project.types = [epic_type, story_type, task_type, other_type]
      version
    end

    it "moves an work_package to a project where backlogs is disabled while using versions" do
      project2 = create(:project, name: "Project 2", types: [epic_type, story_type, task_type, other_type])
      project2.enabled_module_names = project2.enabled_module_names - ["backlogs"]
      project2.save!
      project2.reload

      work_package1 = create(:work_package, type_id: task_type.id, status_id: status.id, project_id: project.id)
      work_package2 = create(:work_package, parent_id: work_package1.id, type_id: task_type.id, status_id: status.id,
                                            project_id: project.id)
      work_package3 = create(:work_package, parent_id: work_package2.id, type_id: task_type.id, status_id: status.id,
                                            project_id: project.id)

      work_package1.reload
      work_package1.version_id = version.id
      work_package1.save!

      work_package1.reload
      work_package2.reload
      work_package3.reload

      move_to_project(work_package3, project2)

      work_package1.reload
      work_package2.reload
      work_package3.reload

      move_to_project(work_package2, project2)

      work_package1.reload
      work_package2.reload
      work_package3.reload

      expect(work_package3.project).to eq(project2)
      expect(work_package2.project).to eq(project2)
      expect(work_package1.project).to eq(project)

      expect(work_package3.version_id).to be_nil
      expect(work_package2.version_id).to be_nil
      expect(work_package1.version_id).to eq(version.id)
    end

    it "rebuilds positions" do
      e1 = create_work_package(type_id: epic_type.id)
      s2 = create_work_package(type_id: story_type.id)
      s3 = create_work_package(type_id: story_type.id)
      s4 = create_work_package(type_id: story_type.id)
      s5 = create_work_package(type_id: story_type.id)
      t3 = create_work_package(type_id: task_type.id)
      o9 = create_work_package(type_id: other_type.id)

      [e1, s2, s3, s4, s5].each(&:move_to_bottom)

      # Messing around with positions
      s3.update_column(:position, nil)
      s4.update_column(:position, nil)

      t3.update_column(:position, 3)
      o9.update_column(:position, 9)

      version.rebuild_story_positions(project)

      work_packages = version
                      .work_packages
                      .where(project_id: project)
                      .order(Arel.sql("COALESCE(position, 0) ASC, id ASC"))

      expect(work_packages.map(&:position)).to eq([nil, nil, 1, 2, 3, 4, 5])
      expect(work_packages.map(&:subject)).to eq([t3, o9, e1, s2, s5, s3, s4].map(&:subject))

      # Makes sure, that all work_package subjects are uniq, so that the above
      # assertion works as expected
      expect(work_packages.map(&:subject).uniq.size).to eq(7)
    end
  end
end
