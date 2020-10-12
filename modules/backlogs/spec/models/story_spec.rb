#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Story, type: :model do
  let(:user) { @user ||= FactoryBot.create(:user) }
  let(:role) { @role ||= FactoryBot.create(:role) }
  let(:status1) { @status1 ||= FactoryBot.create(:status, name: 'status 1', is_default: true) }
  let(:type_feature) { @type_feature ||= FactoryBot.create(:type_feature) }
  let(:version) { @version ||= FactoryBot.create(:version, project: project) }
  let(:version2) { FactoryBot.create(:version, project: project) }
  let(:sprint) { @sprint ||= FactoryBot.create(:sprint, project: project) }
  let(:issue_priority) { @issue_priority ||= FactoryBot.create(:priority) }
  let(:task_type) { FactoryBot.create(:type_task) }
  let(:task) {
    FactoryBot.create(:story, version: version,
                               project: project,
                               status: status1,
                               type: task_type,
                               priority: issue_priority)
  }
  let(:story1) {
    FactoryBot.create(:story, version: version,
                               project: project,
                               status: status1,
                               type: type_feature,
                               priority: issue_priority)
  }

  let(:story2) {
    FactoryBot.create(:story, version: version,
                               project: project,
                               status: status1,
                               type: type_feature,
                               priority: issue_priority)
  }

  let(:project) do
    unless @project
      @project = FactoryBot.build(:project)
      @project.members = [FactoryBot.build(:member, principal: user,
                                                     project: @project,
                                                     roles: [role])]
    end
    @project
  end

  before(:each) do
    ActionController::Base.perform_caching = false

    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'points_burn_direction' => 'down',
                                                                         'wiki_template'         => '',
                                                                         'card_spec'             => 'Sattleford VM-5040',
                                                                         'story_types'           => [type_feature.id.to_s],
                                                                         'task_type'             => task_type.id.to_s })
    project.types << task_type
  end

  describe 'Class methods' do
    describe '#backlogs' do
      describe "WITH one sprint
                WITH the sprint having 1 story" do
        before(:each) do
          story1
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to match_array([story1]) }
      end

      describe "WITH two sprints
                WITH two stories
                WITH one story per sprint
                WITH querying for the two sprints" do
        before do
          version2
          story1
          story2.version_id = version2.id
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id, version2.id])[version.id]).to match_array([story1]) }
        it { expect(Story.backlogs(project, [version.id, version2.id])[version2.id]).to match_array([story2]) }
      end

      describe "WITH two sprints
                WITH two stories
                WITH one story per sprint
                WITH querying one sprints" do
        before do
          version2
          story1

          story2.version_id = version2.id
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to match_array([story1]) }
        it { expect(Story.backlogs(project, [version.id])[version2.id]).to be_empty }
      end

      describe "WITH two sprints
                WITH two stories
                WITH one story per sprint
                WITH querying for the two sprints
                WITH one sprint beeing in another project" do
        before do
          story1

          other_project = FactoryBot.create(:project)
          version2.update! project_id: other_project.id

          story2.version_id = version2.id
          story2.project = other_project
          # reset memoized versions to reflect changes above
          story2.instance_variable_set('@assignable_versions', nil)
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id, version2.id])[version.id]).to match_array([story1]) }
        it { expect(Story.backlogs(project, [version.id, version2.id])[version2.id]).to be_empty }
      end

      describe "WITH one sprint
                WITH the sprint having one story in this project and one story in another project" do
        before(:each) do
          version.sharing = 'system'
          version.save!

          another_project = FactoryBot.create(:project)

          story1
          story2.project = another_project
          story2.save!
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to match_array([story1]) }
      end

      describe "WITH one sprint
                WITH the sprint having two storys
                WITH one beeing the child of the other" do
        before(:each) do
          story1.parent_id = story2.id

          story1.save
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to match_array([story1, story2]) }
      end

      describe "WITH one sprint
                WITH the sprint having one story
                WITH the story having a child task" do
        before(:each) do
          task.parent_id = story1.id

          task.save
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to match_array([story1]) }
      end

      describe "WITH one sprint
                WITH the sprint having one story and one task
                WITH the two having no connection" do
        before(:each) do
          task
          story1
        end

        it { expect(Story.backlogs(project, [version.id])[version.id]).to match_array([story1]) }
      end
    end
  end
end
