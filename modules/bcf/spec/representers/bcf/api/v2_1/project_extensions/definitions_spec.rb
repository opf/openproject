#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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

describe Bcf::API::V2_1::ProjectExtensions::Definitions, 'rendering' do
  shared_let(:type_task) { FactoryBot.create :type_task, name: 'My BCF type' }
  shared_let(:project) { FactoryBot.create(:project, types: [type_task]) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:instance) { described_class.new(project: project, user: user) }

  describe '#topic_type' do
    subject  { instance.topic_type }

    it 'returns the project type names' do
      expect(subject).to eq ['My BCF type']
    end
  end

  describe '#topic_status' do
    let!(:default_status) { FactoryBot.create :default_status  }
    let!(:status) { FactoryBot.create :status  }
    subject  { instance.topic_status }

    it 'returns default status only' do
      expect(subject).to eq [default_status.name]
    end
  end

  describe '#priority' do
    let!(:priority) { FactoryBot.create :default_priority  }
    subject  { instance.priority }

    it 'returns statuses for the available types' do
      expect(subject).to eq [priority.name]
    end
  end

  describe '#user_id_type' do
    let!(:other_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: [:view_work_packages])
    end
    subject  { instance.user_id_type }

    before do
      allow(user)
        .to receive(:allowed_to?).with(:view_members, project)
        .and_return is_permitted
    end

    context 'with permissions' do
      let(:is_permitted) { true }

      it 'returns the user as assignee' do
        expect(subject).to eq [other_user.mail]
      end
    end

    context 'with no permissions' do
      let(:is_permitted) { false }

      it 'returns nothing' do
        expect(subject).to eq []
      end
    end
  end

  describe '#project_actions' do
    subject  { instance.project_actions }

    it 'includes nothing if not permitted' do
      allow(user).to receive(:allowed_to?).and_return false
      expect(subject).to be_empty
    end

    it 'includes `update` if edit_project permission' do
      allow(user).to receive(:allowed_to?).and_return false
      allow(user).to receive(:allowed_to?).with(:edit_project, project).and_return true

      expect(subject).to include 'update'
    end

    it 'includes `createTopic` if edit_project permission' do
      allow(user).to receive(:allowed_to?).and_return false
      allow(user).to receive(:allowed_to?).with(:manage_bcf, project).and_return true

      expect(subject).to include 'createTopic'
    end
  end

  describe '#topic_actions' do
    subject  { instance.topic_actions }

    it 'includes nothing if not permitted' do
      allow(user).to receive(:allowed_to?).and_return false
      expect(subject).to be_empty
    end

    it 'includes `update` if manage_bcf permission' do
      allow(user).to receive(:allowed_to?).and_return false
      allow(user).to receive(:allowed_to?).with(:manage_bcf, project).and_return true

      expect(subject).to match_array %w[update updateRelatedTopics updateFiles createViewpoint]
    end
  end
end
