#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "services/base_services/behaves_like_create_service"

RSpec.describe Members::CreateService, "integration", type: :model do
  let(:user1) { create(:admin) }
  let(:user2) { create(:user) }
  let(:group) { create(:group, members: [user1, user2]) }
  let(:instance) { described_class.new(user: user1) }

  subject { instance.call(params) }

  describe "with a global membership" do
    let(:global_role) { create(:global_role) }
    let(:params) do
      {
        principal: group,
        project_id: nil,
        role_ids: [global_role.id]
      }
    end

    it "inherits the membership to all users", :aggregate_failures do
      expect { subject }.to change(MemberRole, :count).by(3)
      expect(subject).to be_success

      group.users.each do |user|
        members = Member.where(user_id: user.id, project_id: nil)
        expect(members.count).to eq 1
        expect(members.first.roles).to eq [global_role]
      end
    end
  end
end
