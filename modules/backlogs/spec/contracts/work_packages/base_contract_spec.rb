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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe WorkPackages::BaseContract, type: :model do
  let(:instance) { described_class.new(work_package, user) }
  let(:type_feature) { FactoryBot.build(:type_feature) }
  let(:type_task) { FactoryBot.build(:type_task) }
  let(:type_bug) { FactoryBot.build(:type_bug) }
  let(:version1) { FactoryBot.build_stubbed(:version, name: 'Version1', project: p) }
  let(:version2) { FactoryBot.build_stubbed(:version, name: 'Version2', project: p) }
  let(:role) { FactoryBot.build(:role) }
  let(:user) { FactoryBot.build(:admin) }
  let(:issue_priority) { FactoryBot.build(:priority) }
  let(:status) { FactoryBot.build_stubbed(:status, name: 'status 1', is_default: true) }

  let(:project) do
    p = FactoryBot.build(:project, members: [FactoryBot.build(:member,
                                                                principal: user,
                                                                roles: [role])],
                                    types: [type_feature, type_task, type_bug])

    allow(p)
      .to receive(:assignable_versions)
      .and_return([version1,
                   version2])

    p.enabled_module_names += ['backlogs']

    p
  end

  let(:other_project) do
    p = FactoryBot.build(:project, members: [FactoryBot.build(:member,
                                                                principal: user,
                                                                roles: [role])],
                                    types: [type_feature, type_task, type_bug])

    allow(p)
      .to receive(:assignable_versions)
      .and_return([version1,
                   version2])
    p.enabled_module_names += ['backlogs']

    p
  end

  let(:story) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                              subject: 'Story',
                              project: project,
                              type: type_feature,
                              version: version1,
                              status: status,
                              author: user,
                              priority: issue_priority)
  end

  let(:story2) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                              subject: 'Story2',
                              project: project,
                              type: type_feature,
                              version: version1,
                              status: status,
                              author: user,
                              priority: issue_priority)
  end

  let(:task) {
    FactoryBot.build_stubbed(:stubbed_work_package,
                              subject: 'Task',
                              type: type_task,
                              version: version1,
                              project: project,
                              status: status,
                              author: user,
                              priority: issue_priority)
  }

  let(:task2) {
    FactoryBot.build_stubbed(:stubbed_work_package,
                              subject: 'Task2',
                              type: type_task,
                              version: version1,
                              project: project,
                              status: status,
                              author: user,
                              priority: issue_priority)
  }

  let(:bug) {
    FactoryBot.build_stubbed(:stubbed_work_package,
                              subject: 'Bug',
                              type: type_bug,
                              version: version1,
                              project: project,
                              status: status,
                              author: user,
                              priority: issue_priority)
  }

  let(:bug2) {
    FactoryBot.build_stubbed(:stubbed_work_package,
                              subject: 'Bug2',
                              type: type_bug,
                              version: version1,
                              project: project,
                              status: status,
                              author: user,
                              priority: issue_priority)
  }

  subject(:valid) { instance.validate }

  before(:each) do
    project.save!

    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'points_burn_direction' => 'down',
                                                                         'wiki_template'         => '',
                                                                         'card_spec'             => 'Sattleford VM-5040',
                                                                         'story_types'           => [type_feature.id],
                                                                         'task_type'             => type_task.id.to_s })
  end

  shared_examples_for 'is valid' do
    it 'is valid' do
      expect(subject).to be_truthy
    end
  end

  describe 'version being restricted' do
    shared_examples_for 'is invalid and notes the error' do
      it 'is invalid and notes the error' do
        expect(subject).to be_falsey
        expect(instance.errors.symbols_for(:version_id))
          .to match_array([:task_version_must_be_the_same_as_story_version])
      end
    end

    shared_examples_for 'version being restricted by the parent' do
      before(:each) do
        work_package.parent = parent unless work_package.parent.present?
      end

      describe 'WITHOUT a version and the parent also having no version' do
        before(:each) do
          parent.version = nil
          work_package.version = nil
        end

        it_behaves_like 'is valid'
      end

      describe 'WITHOUT a version and the parent having a version' do
        before(:each) do
          parent.version = version1
          work_package.version = nil
        end

        it_behaves_like 'is invalid and notes the error'
      end

      describe 'WITH a version and the parent having a different version' do
        before(:each) do
          parent.version = version1
          work_package.version = version2
        end

        it_behaves_like 'is invalid and notes the error'
      end

      describe 'WITH a version and the parent having the same version' do
        before(:each) do
          parent.version = version1
          work_package.version = version1
        end

        it_behaves_like 'is valid'
      end

      describe 'WITH a version and the parent having no version' do
        before(:each) do
          parent.version = nil
          work_package.version = version1
        end

        it_behaves_like 'is invalid and notes the error'
      end
    end

    shared_examples_for 'version not being restricted by the parent' do
      before(:each) do
        work_package.parent = parent unless work_package.parent.present?
      end

      describe 'WITHOUT a version and the parent also having no version' do
        before(:each) do
          parent.version = nil
          work_package.version = nil
        end

        it_behaves_like 'is valid'
      end

      describe 'WITHOUT a version and the parent having a version' do
        before(:each) do
          parent.version = version1
          work_package.version = nil
        end

        it_behaves_like 'is valid'
      end

      describe 'WITH a version and the parent having a different version' do
        before(:each) do
          parent.version = version1
          work_package.version = version2
        end

        it_behaves_like 'is valid'
      end

      describe 'WITH a version and the parent having the same version' do
        before(:each) do
          parent.version = version1
          work_package.version = version1
        end

        it_behaves_like 'is valid'
      end

      describe 'WITH a version and the parent having no version' do
        before(:each) do
          parent.version = nil
          work_package.version = version1
        end

        it_behaves_like 'is valid'
      end
    end

    shared_examples_for 'version without restriction' do
      describe 'WITHOUT a version' do
        before(:each) do
          work_package.version = nil
        end

        it_behaves_like 'is valid'
      end

      describe 'WITH a version' do
        before(:each) do
          work_package.version = version1
        end

        it_behaves_like 'is valid'
      end
    end

    describe 'WITH a story' do
      let(:work_package) { story }

      describe 'WITHOUT a parent work_package' do
        it_should_behave_like 'version without restriction'
      end

      describe "WITH a story as its parent" do
        let(:parent) { story2 }

        it_should_behave_like 'version not being restricted by the parent'
      end

      describe "WITH a non backlogs tracked work_package as its parent" do
        let(:parent) { bug }

        it_should_behave_like 'version not being restricted by the parent'
      end
    end

    describe 'WITH a task' do
      let(:work_package) { task }

      describe 'WITHOUT a parent work_package (would then be an impediment)' do
        it_should_behave_like 'version without restriction'
      end

      describe "WITH a task as its parent" do
        before(:each) do
          task.parent = task2
        end

        let(:parent) { task2 }

        it_should_behave_like 'version being restricted by the parent'
      end

      describe "WITH a story as its parent" do
        let(:parent) { story }

        it_should_behave_like 'version being restricted by the parent'
      end

      describe "WITH a non backlogs tracked work_package as its parent" do
        let(:parent) { bug }

        it_should_behave_like 'version not being restricted by the parent'
      end
    end

    describe 'WITH a non backlogs work_package' do
      let(:work_package) { bug }

      describe 'WITHOUT a parent work_package' do
        it_should_behave_like 'version without restriction'
      end

      describe "WITH a task as its parent" do
        let(:parent) { task2 }

        it_should_behave_like 'version not being restricted by the parent'
      end

      describe "WITH a story as its parent" do
        let(:parent) { story }

        it_should_behave_like 'version not being restricted by the parent'
      end

      describe "WITH a non backlogs tracked work_package as its parent" do
        let(:parent) { bug2 }

        it_should_behave_like 'version not being restricted by the parent'
      end
    end
  end

  describe 'parent has to be in same project' do
    shared_examples_for 'is invalid and notes the error' do
      it 'is invalid and notes the error' do
        expect(subject).to be_falsey
        expect(instance.errors.symbols_for(:parent_id))
          .to match_array([:parent_child_relationship_across_projects])
      end
    end

    shared_examples_for 'project id restricted by parent' do
      describe 'WITH the parent having a different project' do
        before do
          parent.project = other_project
          work_package.parent = parent
        end

        it_behaves_like 'is invalid and notes the error'
      end

      describe 'WITH the work_package having a different project' do
        before do
          work_package.parent = parent
          work_package.project = other_project
        end

        it_behaves_like 'is invalid and notes the error'
      end
    end

    shared_examples_for 'project id unrestricted by parent' do
      describe 'WITH the parent having a different project' do
        before do
          parent.project = other_project
          work_package.parent = parent
        end

        it_behaves_like 'is valid'
      end

      describe 'WITH the work_package having a different project' do
        before do
          work_package.parent = parent
          work_package.project = other_project
        end

        it_behaves_like 'is valid'
      end
    end

    describe 'WITH a task' do
      let(:work_package) { task }

      describe 'WITH a story as its parent' do
        let(:parent) { story }

        it_behaves_like 'project id restricted by parent'
      end

      describe 'WITH a non backlogs work package as its parent' do
        let(:parent) { bug }

        it_behaves_like 'project id unrestricted by parent'
      end
    end

    describe 'WITH a story' do
      let(:work_package) { story }

      describe 'WITH a story as its parent' do
        let(:parent) { story }

        it_behaves_like 'project id unrestricted by parent'
      end

      describe 'WITH a non backlogs work package as its parent' do
        let(:parent) { bug }

        it_behaves_like 'project id unrestricted by parent'
      end
    end

    describe 'WITH a non backlogs work package' do
      let(:work_package) { bug }

      describe 'WITH a story as its parent' do
        let(:parent) { story }

        it_behaves_like 'project id unrestricted by parent'
      end

      describe 'WITH a non backlogs work package as its parent' do
        let(:parent) { bug2 }

        it_behaves_like 'project id unrestricted by parent'
      end
    end
  end
end
