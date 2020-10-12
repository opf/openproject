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

describe Bim::Bcf::API::V2_1::ProjectExtensions::Representer, 'rendering' do
  let(:type_task) { FactoryBot.build_stubbed :type_task, name: 'My BCF type' }
  let(:status) { FactoryBot.build_stubbed(:status) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:project) do
    FactoryBot.build_stubbed(:project).tap do |p|
      allow(p)
        .to receive(:possible_assignees)
        .and_return([user])
    end
  end
  let(:work_package) { FactoryBot.build_stubbed(:stubbed_work_package, project: project) }
  let(:priority) { FactoryBot.build_stubbed(:priority) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract) do
    double('contract',
           user: user,
           model: work_package,
           assignable_types: [type_task],
           assignable_priorities: [priority],
           assignable_statuses: [status])
  end
  let(:instance) { described_class.new(contract) }
  let(:subject) { instance.to_json }
  let(:permissions) { %i[manage_bcf edit_project] }

  before do
    allow(user)
      .to receive(:allowed_to?) do |permission, context|
      context == project && permissions.include?(permission)
    end
  end

  shared_examples_for 'empty when lacking manage bcf' do
    let(:permissions) { %i[edit_project] }

    it_behaves_like 'attribute' do
      let(:value) { [] }
    end
  end

  describe 'attributes' do
    describe 'topic_type' do
      let(:path) { 'topic_type' }

      it_behaves_like 'attribute' do
        let(:value) { [type_task.name] }
      end

      it_behaves_like 'empty when lacking manage bcf'
    end

    describe 'topic_status' do
      let(:path) { 'topic_status' }

      it_behaves_like 'attribute' do
        let(:value) { [status.name] }
      end

      it_behaves_like 'empty when lacking manage bcf'
    end

    describe 'topic_actions' do
      let(:path) { 'topic_actions' }

      it_behaves_like 'attribute' do
        let(:value) { %w[update updateRelatedTopics updateFiles createViewpoint] }
      end

      it_behaves_like 'empty when lacking manage bcf'
    end

    describe 'priority' do
      let(:path) { 'priority' }

      it_behaves_like 'attribute' do
        let(:value) { [priority.name] }
      end

      it_behaves_like 'empty when lacking manage bcf'
    end

    describe 'user_id_type' do
      let(:path) { 'user_id_type' }
      let(:permissions) { %i[manage_bcf view_members edit_project] }

      it_behaves_like 'attribute' do
        let(:value) { [user.mail] }
      end

      it_behaves_like 'empty when lacking manage bcf'

      context 'when lacking view_members' do
        let(:permissions) { %i[manage_bcf edit_project] }

        it_behaves_like 'attribute' do
          let(:value) { [] }
        end
      end
    end

    describe 'project_actions' do
      let(:path) { 'project_actions' }

      it_behaves_like 'attribute' do
        let(:value) { %w(update viewTopic createTopic) }
      end

      context 'with only view_linked_issues' do
        let(:permissions) { %i[view_linked_issues] }

        it_behaves_like 'attribute' do
          let(:value) { %w[viewTopic] }
        end
      end

      context 'when lacking manage_bcf' do
        let(:permissions) { %i[edit_project] }

        it_behaves_like 'attribute' do
          let(:value) { ['update'] }
        end
      end

      context 'when lacking edit_project' do
        let(:permissions) { %i[manage_bcf] }

        it_behaves_like 'attribute' do
          let(:value) { %w[viewTopic createTopic] }
        end
      end
    end

    describe 'topic_label' do
      let(:path) { 'topic_label' }

      it_behaves_like 'attribute' do
        let(:value) { [] }
      end
    end

    describe 'snippet_type' do
      let(:path) { 'snippet_type' }

      it_behaves_like 'attribute' do
        let(:value) { [] }
      end
    end

    describe 'stage' do
      let(:path) { 'stage' }

      it_behaves_like 'attribute' do
        let(:value) { [] }
      end
    end

    describe 'comment_actions' do
      let(:path) { 'comment_actions' }

      it_behaves_like 'attribute' do
        let(:value) { [] }
      end
    end
  end
end
