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
  let(:task) {
    FactoryGirl.build(:task, type: type_task,
                             project: project,
                             author: user,
                             priority: issue_priority,
                             status: status1)
  }
  let(:feature) {
    FactoryGirl.build(:work_package, type: type_feature,
                                     project: project,
                                     author: user,
                                     priority: issue_priority,
                                     status: status1)
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

  let(:status1) { @status1 ||= FactoryGirl.create(:status, name: 'status 1', is_default: true) }
  let(:status2) { @status2 ||= FactoryGirl.create(:status, name: 'status 2') }
  let(:type_workflow) {
    @workflow ||= Workflow.create(type_id: type_task.id,
                                  old_status: status1,
                                  new_status: status2,
                                  role: role)
  }
  let(:impediment) {
    FactoryGirl.build(:impediment, author: user,
                                   fixed_version: version,
                                   assigned_to: user,
                                   priority: issue_priority,
                                   project: project,
                                   type: type_task,
                                   status: status1)
  }

  before(:each) do
    ActionController::Base.perform_caching = false

    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'points_burn_direction' => 'down',
                                                                         'wiki_template'         => '',
                                                                         'card_spec'             => 'Sattleford VM-5040',
                                                                         'story_types'           => [type_feature.id.to_s],
                                                                         'task_type'             => type_task.id.to_s })

    allow(User).to receive(:current).and_return(user)
    issue_priority.save
    status1.save
    project.save
    type_workflow.save
  end

  describe 'class methods' do
    describe '#create_with_relationships' do
      before(:each) do
        @impediment_subject = 'Impediment A'
        role.permissions = [:create_impediments]
        role.save
      end

      shared_examples_for 'impediment creation' do
        it { expect(@impediment.subject).to eql @impediment_subject }
        it { expect(@impediment.author).to eql User.current }
        it { expect(@impediment.project).to eql project }
        it { expect(@impediment.fixed_version).to eql version }
        it { expect(@impediment.priority).to eql issue_priority }
        it { expect(@impediment.status).to eql status1 }
        it { expect(@impediment.type).to eql type_task }
        it { expect(@impediment.assigned_to).to eql user }
      end

      shared_examples_for 'impediment creation with 1 blocking relationship' do
        it_should_behave_like 'impediment creation'
        it { expect(@impediment.relations_to.direct.size).to eq(1) }
        it { expect(@impediment.relations_to.direct[0].to).to eql feature }
        it { expect(@impediment.relations_to.direct[0].relation_type).to eql Relation::TYPE_BLOCKS }
      end

      shared_examples_for 'impediment creation with no blocking relationship' do
        it_should_behave_like 'impediment creation'
        it { expect(@impediment.relations_to.direct.size).to eq(0) }
      end

      describe 'WITH a blocking relationship to a story' do
        describe 'WITH the story having the same version' do
          before(:each) do
            feature.fixed_version = version
            feature.save
            @impediment = Impediment.create_with_relationships({ subject: @impediment_subject,
                                                                 assigned_to_id: user.id,
                                                                 blocks_ids: feature.id.to_s,
                                                                 status_id: status1.id,
                                                                 fixed_version_id: version.id },
                                                               project.id)
          end

          it_should_behave_like 'impediment creation with 1 blocking relationship'
          it { expect(@impediment).not_to be_new_record }
          it { expect(@impediment.relations_to.direct[0]).not_to be_new_record }
        end

        describe 'WITH the story having another version' do
          before(:each) do
            feature.fixed_version = FactoryGirl.create(:version, project: project, name: 'another version')
            feature.save
            @impediment = Impediment.create_with_relationships({ subject: @impediment_subject,
                                                                 assigned_to_id: user.id,
                                                                 blocks_ids: feature.id.to_s,
                                                                 status_id: status1.id,
                                                                 fixed_version_id: version.id },
                                                               project.id)
          end

          it_should_behave_like 'impediment creation with no blocking relationship'
          it { expect(@impediment).to be_new_record }
          it { expect(@impediment.errors[:blocks_ids]).to include I18n.t(:can_only_contain_work_packages_of_current_sprint, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end

        describe 'WITH the story being non existent' do
          before(:each) do
            @impediment = Impediment.create_with_relationships({ subject: @impediment_subject,
                                                                 assigned_to_id: user.id,
                                                                 blocks_ids: '0',
                                                                 status_id: status1.id,
                                                                 fixed_version_id: version.id },
                                                               project.id)
          end

          it_should_behave_like 'impediment creation with no blocking relationship'
          it { expect(@impediment).to be_new_record }
          it { expect(@impediment.errors[:blocks_ids]).to include I18n.t(:can_only_contain_work_packages_of_current_sprint, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end
      end

      describe 'WITHOUT a blocking relationship defined' do
        before(:each) do
          @impediment = Impediment.create_with_relationships({ subject: @impediment_subject,
                                                               assigned_to_id: user.id,
                                                               blocks_ids: '',
                                                               status_id: status1.id,
                                                               fixed_version_id: version.id },
                                                             project.id)
        end

        it_should_behave_like 'impediment creation with no blocking relationship'
        it { expect(@impediment).to be_new_record }
        it { expect(@impediment.errors[:blocks_ids]).to include I18n.t(:must_block_at_least_one_work_package, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
      end
    end
  end

  describe 'instance methods' do
    describe '#update_with_relationships' do
      before(:each) do
        role.permissions = [:update_impediments]
        role.save

        feature.fixed_version = version
        feature.save

        @impediment = impediment
        @impediment.blocks_ids = feature.id.to_s
        @impediment.save
      end

      shared_examples_for 'impediment update' do
        it { expect(@impediment.author).to eql user }
        it { expect(@impediment.project).to eql project }
        it { expect(@impediment.fixed_version).to eql version }
        it { expect(@impediment.priority).to eql issue_priority }
        it { expect(@impediment.status).to eql status1 }
        it { expect(@impediment.type).to eql type_task }
        it { expect(@impediment.blocks_ids).to eql @blocks.split(/\D+/).map(&:to_i) }
      end

      shared_examples_for 'impediment update with changed blocking relationship' do
        it_should_behave_like 'impediment update'
        it { expect(@impediment.relations_to.direct.size).to eq(1) }
        it { expect(@impediment.relations_to.direct[0]).not_to be_new_record }
        it { expect(@impediment.relations_to.direct[0].to).to eql @story }
        it { expect(@impediment.relations_to.direct[0].relation_type).to eql Relation::TYPE_BLOCKS }
      end

      shared_examples_for 'impediment update with unchanged blocking relationship' do
        it_should_behave_like 'impediment update'
        it { expect(@impediment.relations_to.direct.size).to eq(1) }
        it { expect(@impediment.relations_to.direct[0]).not_to be_changed }
        it { expect(@impediment.relations_to.direct[0].to).to eql feature }
        it { expect(@impediment.relations_to.direct[0].relation_type).to eql Relation::TYPE_BLOCKS }
      end

      describe 'WHEN changing the blocking relationship to another story' do
        before(:each) do
          @story = FactoryGirl.build(:work_package, subject: 'another story',
                                                    type: type_feature,
                                                    project: project,
                                                    author: user,
                                                    priority: issue_priority,
                                                    status: status1)
        end

        describe 'WITH the story having the same version' do
          before(:each) do
            @story.fixed_version = version
            @story.save
            @blocks = @story.id.to_s
            @impediment.update_with_relationships({ blocks_ids: @blocks,
                                                    status_id: status1.id.to_s })
          end

          it_should_behave_like 'impediment update with changed blocking relationship'
          it { expect(@impediment).not_to be_changed }
        end

        describe 'WITH the story having another version' do
          before(:each) do
            other_version = FactoryGirl.create(:version, project: project, name: 'another version')
            # the assignable versions are cached for performance, we thus have to
            # throw away the cache
            @story.project = Project.find(project.id)

            @story.fixed_version = other_version
            @story.save!
            @blocks = @story.id.to_s
            @saved = @impediment.update_with_relationships({ blocks_ids: @blocks,
                                                             status_id: status1.id.to_s })
          end

          it_should_behave_like 'impediment update with unchanged blocking relationship'
          it 'should not be saved successfully' do
            expect(@saved).to be_falsey
          end
          it { expect(@impediment.errors[:blocks_ids]).to include I18n.t(:can_only_contain_work_packages_of_current_sprint, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end

        describe 'WITH the story beeing non existent' do
          before(:each) do
            @blocks = '0'
            @saved = @impediment.update_with_relationships({ blocks_ids: @blocks,
                                                             status_id: status1.id.to_s })
          end

          it_should_behave_like 'impediment update with unchanged blocking relationship'
          it 'should not be saved successfully' do
            expect(@saved).to be_falsey
          end
          it { expect(@impediment.errors[:blocks_ids]).to include I18n.t(:can_only_contain_work_packages_of_current_sprint, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end
      end

      describe 'WITHOUT a blocking relationship defined' do
        before(:each) do
          @blocks = ''
          @saved = @impediment.update_with_relationships({ blocks_ids: @blocks,
                                                           status_id: status1.id.to_s })
        end

        it_should_behave_like 'impediment update with unchanged blocking relationship'
        it 'should not be saved successfully' do
          expect(@saved).to be_falsey
        end

        it { expect(@impediment.errors[:blocks_ids]).to include I18n.t(:must_block_at_least_one_work_package, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
      end
    end

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
