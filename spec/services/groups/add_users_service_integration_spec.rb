#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Groups::AddUsersService, 'integration', type: :model do
  subject(:service_call) { instance.call(ids: user_ids, message: message) }

  let(:projects) { FactoryBot.create_list :project, 2 }
  let(:role) { FactoryBot.create :role }
  let(:admin) { FactoryBot.create :admin }

  let!(:group) do
    FactoryBot.create :group,
                      member_in_projects: projects,
                      member_through_role: role
  end

  let(:user1) { FactoryBot.create :user }
  let(:user2) { FactoryBot.create :user }
  let(:user_ids) { [user1.id, user2.id] }
  let(:message) { 'Some message' }

  let(:instance) do
    described_class.new(group, current_user: current_user)
  end

  before do
    allow(Notifications::GroupMemberAlteredJob)
      .to receive(:perform_later)
  end

  shared_examples_for 'adds the users to the group and project' do
    it 'adds the users to the group and project' do
      expect(service_call).to be_success

      expect(group.users)
        .to match_array([user1, user2])
      expect(user1.memberships.where(project_id: projects).count).to eq 2
      expect(user1.memberships.map(&:roles).flatten).to match_array [role, role]
      expect(user2.memberships.where(project_id: projects).count).to eq 2
      expect(user2.memberships.map(&:roles).flatten).to match_array [role, role]
    end
  end

  shared_examples_for 'sends notification' do
    it 'on the updated membership' do
      service_call

      ids = defined?(members) ? members : Member.where(principal: user).pluck(:id)

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
        .with(a_collection_containing_exactly(*ids),
              message)
    end
  end

  context 'when an admin user' do
    let(:current_user) { admin }

    it_behaves_like 'adds the users to the group and project'

    it_behaves_like 'sends notification' do
      let(:user) { user_ids }
    end

    context 'when the group is invalid (e.g. required cf not set)' do
      before do
        group
        # The group is now invalid as it has no cv for this field
        FactoryBot.create(:custom_field, type: 'GroupCustomField', is_required: true, field_format: 'int')
      end

      it_behaves_like 'adds the users to the group and project'

      it_behaves_like 'sends notification' do
        let(:user) { user_ids }
      end
    end

    context 'when the user was already a member in a project with the same role' do
      let(:previous_project) { projects.first }
      let!(:user_member) do
        FactoryBot.create(:member,
                          project: previous_project,
                          roles: [role],
                          principal: user1)
      end

      it_behaves_like 'adds the users to the group and project'

      it 'does not update the timestamps on the preexisting membership' do
        # Need to reload so that the timestamps are set by the database
        user_member.reload

        service_call

        expect(Member.find(user_member.id).updated_at)
          .to eql(user_member.updated_at)
      end

      it_behaves_like 'sends notification' do
        let(:members) do
          Member.where(user_id: user_ids).where.not(id: user_member).pluck(:id)
        end
      end
    end

    context 'when the user was already a member in a project with only one role the group adds' do
      let(:project) { FactoryBot.create(:project) }
      let(:roles) { FactoryBot.create_list(:role, 2) }
      let!(:group) do
        FactoryBot.create :group do |g|
          FactoryBot.create(:member,
                            project: project,
                            principal: g,
                            roles: roles)
        end
      end
      let!(:user_member) do
        FactoryBot.create(:member,
                          project: project,
                          roles: [roles.first],
                          principal: user1)
      end

      it 'adds the users to the group and project' do
        expect(service_call).to be_success

        expect(group.users)
          .to match_array([user1, user2])
        expect(user1.memberships.where(project_id: project).map(&:roles).flatten)
          .to match_array(roles)
        expect(user1.memberships.where(project_id: project).map(&:roles).flatten)
          .to match_array(roles)
        expect(user2.memberships.where(project_id: project).count).to eq 1
        expect(user2.memberships.map(&:roles).flatten).to match_array roles
      end

      it 'updates the timestamps on the preexisting membership' do
        service_call

        expect(Member.find(user_member.id).updated_at)
          .not_to eql(user_member.updated_at)
      end

      it_behaves_like 'sends notification' do
        let(:user) { user_ids }
      end
    end

    context 'when the user was already a member in a project with a different role' do
      let(:other_role) { FactoryBot.create(:role) }
      let(:previous_project) { projects.first }
      let!(:user_member) do
        FactoryBot.create(:member,
                          project: previous_project,
                          roles: [other_role],
                          principal: user1)
      end

      it 'adds the users to the group and project' do
        expect(service_call).to be_success

        expect(group.users)
          .to match_array([user1, user2])
        expect(user1.memberships.where(project_id: previous_project).map(&:roles).flatten)
          .to match_array([role, other_role])
        expect(user1.memberships.where(project_id: projects.last).map(&:roles).flatten)
          .to match_array([role])
        expect(user2.memberships.where(project_id: projects).count).to eq 2
        expect(user2.memberships.map(&:roles).flatten).to match_array [role, role]
      end

      it 'updates the timestamps on the preexisting membership' do
        service_call

        expect(Member.find(user_member.id).updated_at)
          .not_to eql(user_member.updated_at)
      end

      it_behaves_like 'sends notification' do
        let(:user) { user_ids }
      end
    end
  end

  context 'when not allowed' do
    let(:current_user) { User.anonymous }

    it 'fails the request' do
      expect(service_call).to be_failure
      expect(service_call.message).to match /may not be accessed/
    end
  end
end
