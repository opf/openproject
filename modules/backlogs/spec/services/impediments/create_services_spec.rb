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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Impediments::CreateService do
  let(:instance) { described_class.new(user: user) }

  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role, permissions: %i(add_work_packages)) }
  let(:type_feature) { FactoryBot.create(:type_feature) }
  let(:type_task) { FactoryBot.create(:type_task) }
  let(:priority) { FactoryBot.create(:priority, is_default: true) }
  let(:feature) {
    FactoryBot.build(:work_package, type: type_feature,
                                     project: project,
                                     author: user,
                                     priority: priority,
                                     status: status1)
  }
  let(:version) { FactoryBot.create(:version, project: project) }

  let(:project) do
    project = FactoryBot.create(:project, types: [type_feature, type_task])

    FactoryBot.create(:member, principal: user,
                                project: project,
                                roles: [role])

    project
  end

  let(:status1) { FactoryBot.create(:status, name: 'status 1', is_default: true) }

  before(:each) do
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'points_burn_direction' => 'down',
                                                                         'wiki_template'         => '',
                                                                         'card_spec'             => 'Sattleford VM-5040',
                                                                         'story_types'           => [type_feature.id.to_s],
                                                                         'task_type'             => type_task.id.to_s })

    login_as user
  end

  let(:impediment_subject) { 'Impediment A' }

  shared_examples_for 'impediment creation' do
    it { expect(subject.subject).to eql impediment_subject }
    it { expect(subject.author).to eql User.current }
    it { expect(subject.project).to eql project }
    it { expect(subject.fixed_version).to eql version }
    it { expect(subject.priority).to eql priority }
    it { expect(subject.status).to eql status1 }
    it { expect(subject.type).to eql type_task }
    it { expect(subject.assigned_to).to eql user }
  end

  shared_examples_for 'impediment creation with 1 blocking relationship' do
    it_should_behave_like 'impediment creation'
    it { expect(subject.relations_to.direct.size).to eq(1) }
    it { expect(subject.relations_to.direct[0].to).to eql feature }
    it { expect(subject.relations_to.direct[0].relation_type).to eql Relation::TYPE_BLOCKS }
  end

  shared_examples_for 'impediment creation with no blocking relationship' do
    it_should_behave_like 'impediment creation'
    it { expect(subject.relations_to.direct.size).to eq(0) }
  end

  describe 'WITH a blocking relationship to a story' do
    describe 'WITH the story having the same version' do
      subject do
        call = instance.call(attributes: { subject: impediment_subject,
                                           assigned_to_id: user.id,
                                           priority_id: priority.id,
                                           blocks_ids: feature.id.to_s,
                                           status_id: status1.id,
                                           fixed_version_id: version.id,
                                           project_id: project.id })
        call.result
      end

      before(:each) do
        feature.fixed_version = version
        feature.save
      end

      it_should_behave_like 'impediment creation with 1 blocking relationship'
      it { expect(subject).not_to be_new_record }
      it { expect(subject.relations_to.direct[0]).not_to be_new_record }
    end

    describe 'WITH the story having another version' do
      subject do
        call = instance.call(attributes: { subject: impediment_subject,
                                           assigned_to_id: user.id,
                                           priority_id: priority.id,
                                           blocks_ids: feature.id.to_s,
                                           status_id: status1.id,
                                           fixed_version_id: version.id,
                                           project_id: project.id })
        call.result
      end

      before(:each) do
        feature.fixed_version = FactoryBot.create(:version, project: project, name: 'another version')
        feature.save
      end

      it_should_behave_like 'impediment creation with no blocking relationship'
      it { expect(subject).to be_new_record }
      it { expect(subject.errors[:blocks_ids]).to include I18n.t(:can_only_contain_work_packages_of_current_sprint, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
    end

    describe 'WITH the story being non existent' do
      subject do
        call = instance.call(attributes: { subject: impediment_subject,
                                           assigned_to_id: user.id,
                                           priority_id: priority.id,
                                           blocks_ids: '0',
                                           status_id: status1.id,
                                           fixed_version_id: version.id,
                                           project_id: project.id })
        call.result
      end

      it_should_behave_like 'impediment creation with no blocking relationship'
      it { expect(subject).to be_new_record }
      it { expect(subject.errors[:blocks_ids]).to include I18n.t(:can_only_contain_work_packages_of_current_sprint, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
    end
  end

  describe 'WITHOUT a blocking relationship defined' do
    subject do
      call = instance.call(attributes: { subject: impediment_subject,
                                         assigned_to_id: user.id,
                                         blocks_ids: '',
                                         priority_id: priority.id,
                                         status_id: status1.id,
                                         fixed_version_id: version.id,
                                         project_id: project.id })
      call.result
    end

    it_should_behave_like 'impediment creation with no blocking relationship'
    it { expect(subject).to be_new_record }
    it { expect(subject.errors[:blocks_ids]).to include I18n.t(:must_block_at_least_one_work_package, scope: [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
  end
end
