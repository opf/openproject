#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Impediment, type: :model do
  let(:user) { @user ||= FactoryGirl.create(:user) }
  let(:role) { @role ||= FactoryGirl.create(:role) }
  let(:type_feature) { @type_feature ||= FactoryGirl.create(:type_feature) }
  let(:type_task) { @type_task ||= FactoryGirl.create(:type_task) }
  let(:issue_priority) { @issue_priority ||= FactoryGirl.create(:priority, is_default: true) }
  let(:status) { FactoryGirl.create(:status) }
  let(:task) {
    FactoryGirl.build(:task, type: type_task,
                             project: project,
                             author: user,
                             priority: issue_priority,
                             status: status)
  }
  let(:feature) {
    FactoryGirl.build(:work_package, type: type_feature,
                                     project: project,
                                     author: user,
                                     priority: issue_priority,
                                     status: status)
  }
  let(:version) { FactoryGirl.create(:version, project: project) }

  let(:project) do
    unless @project
      @project = FactoryGirl.build(:project, types: [type_feature, type_task])
      @project.members = [FactoryGirl.build(:member, principal: user,
                                                     project: @project,
                                                     roles: [role])]
    end
    @project
  end

  let(:impediment) {
    FactoryGirl.build(:impediment, author: user,
                                   fixed_version: version,
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
          feature.fixed_version = version
          feature.save
          task.fixed_version = version
          task.save

          # Using the default association method block_ids (without s) here
          impediment.block_ids = [feature.id, task.id]
        end

        it { expect(impediment.blocks_ids).to eql [feature.id, task.id] }
      end
    end
  end
end
