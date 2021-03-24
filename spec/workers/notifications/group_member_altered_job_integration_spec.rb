#-- encoding: UTF-8

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

describe Notifications::GroupMemberAlteredJob, 'integration', type: :model do
  subject do
    described_class.new.perform(group, member.id)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  let(:group) { FactoryBot.create(:group) }
  let(:role1) { FactoryBot.create(:role) }
  let(:role2) { FactoryBot.create(:role) }
  let(:member) do
    FactoryBot.create(:member,
                      principal: user,
                      project: project,
                      roles: [role1])
  end

  before do
    allow(OpenProject::Notifications).to receive(:send)
  end

  shared_examples_for 'sends notification' do |notification|
    before do
      subject
    end

    it "sends a '#{notification}' notification" do

      expect(OpenProject::Notifications)
        .to have_received(:send)
        .with("OpenProject::Events::#{notification}".constantize,
              member: member)
    end
  end

  context 'when the member has no member_role other than the one by the group' do
    before do
      MemberRole
        .where(role_id: role1.id, member_id: member.id)
        .update_all(inherited_from: group.id)
    end

    it_behaves_like 'sends notification', 'MEMBER_CREATED'
  end

  context 'when the member has a member_role other than the one by the group' do
    before do
      MemberRole.create(role_id: role2.id,
                        member_id: member.id,
                        inherited_from: group.id)
    end

    it_behaves_like 'sends notification', 'MEMBER_UPDATED'
  end
end
