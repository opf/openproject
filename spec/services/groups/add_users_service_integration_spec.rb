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

describe Groups::AddUsersService, 'integration', type: :model do
  let(:projects) { FactoryBot.create_list :project, 2 }
  let(:role) { FactoryBot.create :role }

  let(:group) do
    FactoryBot.create :group,
                      member_in_projects: projects,
                      member_through_role: role
  end

  let(:instance) do
    described_class.new(group, current_user: current_user)
  end

  describe 'adding a user' do
    let(:user1) { FactoryBot.create :user }
    let(:user2) { FactoryBot.create :user }

    let(:user_ids) { [user1.id, user2.id] }
    subject { instance.call(user_ids) }

    context 'as an admin user' do
      using_shared_fixtures :admin
      let(:current_user) { admin }

      it 'adds the users to the group and project' do
        expect(subject).to be_success

        expect(user1.memberships.where(project_id: projects).count).to eq 2
        expect(user1.memberships.map(&:roles).flatten).to eq [role, role]
        expect(user2.memberships.map(&:roles).flatten).to eq [role, role]
      end
    end

    context 'as not allowed' do
      let(:current_user) { User.anonymous }

      it 'fails the request' do
        expect(subject).to be_failure
        expect(subject.message).to match /may not be accessed/
      end
    end
  end
end
