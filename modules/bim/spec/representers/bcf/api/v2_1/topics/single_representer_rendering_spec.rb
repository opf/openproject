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

require 'spec_helper'

require_relative '../shared_examples'

describe Bim::Bcf::API::V2_1::Topics::SingleRepresenter, 'rendering' do
  include API::V3::Utilities::PathHelper

  let(:assignee) { FactoryBot.build_stubbed(:user) }
  let(:creator) { FactoryBot.build_stubbed(:user) }
  let(:modifier) { FactoryBot.build_stubbed(:user) }
  let(:first_journal) { FactoryBot.build_stubbed(:journal, version: 1, user: creator) }
  let(:last_journal) { FactoryBot.build_stubbed(:journal, version: 2, user: modifier) }
  let(:journals) { [first_journal, last_journal] }
  let(:type) { FactoryBot.build_stubbed(:type) }
  let(:status) { FactoryBot.build_stubbed(:status) }
  let(:priority) { FactoryBot.build_stubbed(:priority) }
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             assigned_to: assignee,
                             due_date: Date.today,
                             status: status,
                             priority: priority,
                             type: type).tap do |wp|
      allow(wp)
        .to receive(:journals)
        .and_return(journals)
    end
  end
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:issue) { FactoryBot.build_stubbed(:bcf_issue, work_package: work_package) }
  let(:manage_bcf_allowed) { true }
  let(:statuses) do
    [
      FactoryBot.build_stubbed(:status),
      FactoryBot.build_stubbed(:status)
    ]
  end

  let(:instance) { described_class.new(issue) }

  before do
    login_as(current_user)

    allow(current_user)
      .to receive(:allowed_to?)
      .with(:manage_bcf, issue.project)
      .and_return(manage_bcf_allowed)

    contract = double('contract',
                      model: issue,
                      user: current_user,
                      assignable_statuses: statuses)

    allow(WorkPackages::UpdateContract)
      .to receive(:new)
      .with(work_package, current_user)
      .and_return(contract)
  end

  subject { instance.to_json }

  describe 'attributes' do
    context 'guid' do
      it_behaves_like 'attribute' do
        let(:value) { issue.uuid }
        let(:path) { 'guid' }
      end
    end

    context 'topic_type' do
      it_behaves_like 'attribute' do
        let(:value) { type.name }
        let(:path) { 'topic_type' }
      end
    end

    context 'topic_status' do
      it_behaves_like 'attribute' do
        let(:value) { status.name }
        let(:path) { 'topic_status' }
      end
    end

    context 'priority' do
      it_behaves_like 'attribute' do
        let(:value) { priority.name }
        let(:path) { 'priority' }
      end
    end

    context 'reference_links' do
      it_behaves_like 'attribute' do
        let(:value) { [api_v3_paths.work_package(work_package.id)] }
        let(:path) { 'reference_links' }
      end
    end

    context 'title' do
      it_behaves_like 'attribute' do
        let(:value) { work_package.subject }
        let(:path) { 'title' }
      end
    end

    context 'index' do
      it_behaves_like 'attribute' do
        let(:value) { issue.index }
        let(:path) { 'index' }
      end
    end

    context 'labels' do
      it_behaves_like 'attribute' do
        let(:value) { issue.labels }
        let(:path) { 'labels' }
      end
    end

    context 'creation_date' do
      it_behaves_like 'attribute' do
        let(:value) { work_package.created_at.iso8601 }
        let(:path) { 'creation_date' }
      end
    end

    context 'creation_author' do
      it_behaves_like 'attribute' do
        let(:value) { work_package.author.mail }
        let(:path) { 'creation_author' }
      end
    end

    context 'modified_date' do
      it_behaves_like 'attribute' do
        let(:value) { work_package.updated_at.iso8601 }
        let(:path) { 'modified_date' }
      end
    end

    context 'modified_author' do
      it_behaves_like 'attribute' do
        let(:value) { modifier.mail }
        let(:path) { 'modified_author' }
      end
    end

    context 'description' do
      it_behaves_like 'attribute' do
        let(:value) { work_package.description }
        let(:path) { 'description' }
      end
    end

    context 'due_date' do
      it_behaves_like 'attribute' do
        let(:value) { work_package.due_date.iso8601 }
        let(:path) { 'due_date' }
      end
    end

    context 'assigned_to' do
      it_behaves_like 'attribute' do
        let(:value) { work_package.assigned_to.mail }
        let(:path) { 'assigned_to' }
      end
    end

    context 'stage' do
      it_behaves_like 'attribute' do
        let(:value) { issue.stage }
        let(:path) { 'stage' }
      end
    end
  end

  describe 'authorization' do
    context 'if the user has manage_bcf permission' do
      it 'lists the actions' do
        expect(subject)
          .to be_json_eql(%w[update updateRelatedTopics updateFiles createViewpoint].to_json)
          .at_path('authorization/topic_actions')
      end

      it 'lists the allowed statuses' do
        expect(subject)
          .to be_json_eql(statuses.map(&:name).to_json)
          .at_path('authorization/topic_status')
      end
    end

    context 'if the user lacks manage_bcf permission' do
      let(:manage_bcf_allowed) { false }

      it 'signals lack of available actions' do
        expect(subject)
          .to be_json_eql([])
          .at_path('authorization/topic_actions')
      end

      it 'lists no allowed status' do
        expect(subject)
          .to be_json_eql([].to_json)
          .at_path('authorization/topic_status')
      end
    end
  end
end
