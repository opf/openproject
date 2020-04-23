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

describe Impediment, type: :model do
  let(:user) { @user ||= FactoryBot.create(:user) }
  let(:role) { @role ||= FactoryBot.create(:role) }
  let(:type_feature) { @type_feature ||= FactoryBot.create(:type_feature) }
  let(:type_task) { @type_task ||= FactoryBot.create(:type_task) }
  let(:issue_priority) { @issue_priority ||= FactoryBot.create(:priority, is_default: true) }
  let(:status) { FactoryBot.create(:status) }
  let(:task) {
    FactoryBot.build(:task, type: type_task,
                             project: project,
                             author: user,
                             priority: issue_priority,
                             status: status)
  }
  let(:feature) {
    FactoryBot.build(:work_package, type: type_feature,
                                     project: project,
                                     author: user,
                                     priority: issue_priority,
                                     status: status)
  }
  let(:version) { FactoryBot.create(:version, project: project) }

  let(:project) do
    unless @project
      @project = FactoryBot.build(:project, types: [type_feature, type_task])
      @project.members = [FactoryBot.build(:member, principal: user,
                                                     project: @project,
                                                     roles: [role])]
    end
    @project
  end

  let(:impediment) {
    FactoryBot.build(:impediment, author: user,
                                   version: version,
                                   assigned_to: user,
                                   priority: issue_priority,
                                   project: project,
                                   type: type_task,
                                   status: status)
  }

  before(:each) do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
      .and_return({ 'points_burn_direction' => 'down',
                    'wiki_template'         => '',
                    'card_spec'             => 'Sattleford VM-5040',
                    'story_types'           => [type_feature.id.to_s],
                    'task_type'             => type_task.id.to_s })

    login_as user
  end

  describe 'instance methods' do
    describe 'blocks_ids=/blocks_ids' do
      describe 'WITH an integer' do
        it do
          impediment.blocks_ids = 2
          expect(impediment.blocks_ids).to eql [2]
        end
      end

      describe 'WITH a string' do
        it do
          impediment.blocks_ids = '1, 2, 3'
          expect(impediment.blocks_ids).to eql [1, 2, 3]
        end
      end

      describe 'WITH an array' do
        it do
          impediment.blocks_ids = [1, 2, 3]
          expect(impediment.blocks_ids).to eql [1, 2, 3]
        end
      end

      describe 'WITH only prior blockers defined' do
        before(:each) do
          feature.version = version
          feature.save
          task.version = version
          task.save

          # Using the default association method block_ids (without s) here
          impediment.block_ids = [feature.id, task.id]
        end

        it { expect(impediment.blocks_ids).to eql [feature.id, task.id] }
      end
    end
  end
end
