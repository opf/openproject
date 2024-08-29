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

RSpec.describe Story do
  let(:user) { @user ||= create(:user) }
  let(:role) { @role ||= create(:project_role) }
  let(:status1) { @status1 ||= create(:status, name: "status 1", is_default: true) }
  let(:type_feature) { @type_feature ||= create(:type_feature) }
  let(:version) { @version ||= create(:version, project:) }
  let(:version2) { create(:version, project:) }
  let(:sprint) { @sprint ||= create(:sprint, project:) }
  let(:issue_priority) { @issue_priority ||= create(:priority) }
  let(:task_type) { create(:type_task) }
  let(:task) do
    create(:story, version:,
                   project:,
                   status: status1,
                   type: task_type,
                   priority: issue_priority)
  end
  let(:story1) do
    create(:story, version:,
                   project:,
                   status: status1,
                   type: type_feature,
                   priority: issue_priority)
  end

  let(:story2) do
    create(:story, version:,
                   project:,
                   status: status1,
                   type: type_feature,
                   priority: issue_priority)
  end

  let(:project) do
    unless @project
      @project = build(:project)
      @project.members = [build(:member, principal: user,
                                         project: @project,
                                         roles: [role])]
    end
    @project
  end

  before do
    ActionController::Base.perform_caching = false

    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "points_burn_direction" => "down",
                                                                         "wiki_template" => "",
                                                                         "story_types" => [type_feature.id.to_s],
                                                                         "task_type" => task_type.id.to_s })
    project.types << task_type
  end

  describe "Class methods" do
    describe "#backlogs" do
      describe "WITH one sprint " \
               "WITH the sprint having 1 story" do
        before do
          story1
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to contain_exactly(story1) }
      end

      describe "WITH two sprints " \
               "WITH two stories " \
               "WITH one story per sprint " \
               "WITH querying for the two sprints" do
        before do
          version2
          story1
          story2.version_id = version2.id
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id, version2.id])[version.id]).to contain_exactly(story1) }
        it { expect(Story.backlogs(project, [version.id, version2.id])[version2.id]).to contain_exactly(story2) }
      end

      describe "WITH two sprints " \
               "WITH two stories " \
               "WITH one story per sprint " \
               "WITH querying one sprints" do
        before do
          version2
          story1

          story2.version_id = version2.id
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to contain_exactly(story1) }
        it { expect(Story.backlogs(project, [version.id])[version2.id]).to be_empty }
      end

      describe "WITH two sprints " \
               "WITH two stories " \
               "WITH one story per sprint " \
               "WITH querying for the two sprints " \
               "WITH one sprint being in another project" do
        before do
          story1

          other_project = create(:project)
          version2.update! project_id: other_project.id

          story2.version_id = version2.id
          story2.project = other_project
          # reset memoized versions to reflect changes above
          story2.instance_variable_set(:@assignable_versions, nil)
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id, version2.id])[version.id]).to contain_exactly(story1) }
        it { expect(Story.backlogs(project, [version.id, version2.id])[version2.id]).to be_empty }
      end

      describe "WITH one sprint " \
               "WITH the sprint having one story in this project and one story in another project" do
        before do
          version.sharing = "system"
          version.save!

          another_project = create(:project)

          story1
          story2.project = another_project
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to contain_exactly(story1) }
      end

      describe "WITH one sprint " \
               "WITH the sprint having two storys " \
               "WITH one being the child of the other" do
        before do
          story1.parent_id = story2.id

          story1.save
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to contain_exactly(story1, story2) }
      end

      describe "WITH one sprint " \
               "WITH the sprint having one story " \
               "WITH the story having a child task" do
        before do
          task.parent_id = story1.id

          task.save
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to contain_exactly(story1) }
      end

      describe "WITH one sprint " \
               "WITH the sprint having one story and one task " \
               "WITH the two having no connection" do
        before do
          task
          story1
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to contain_exactly(story1) }
      end
    end
  end
end
