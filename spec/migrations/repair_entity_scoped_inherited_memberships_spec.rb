# frozen_string_literal: true

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
require Rails.root.join("db/migrate/20260918125750_repair_entity_scoped_inherited_memberships.rb")

RSpec.describe RepairEntityScopedInheritedMemberships, type: :model do
  subject { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }

  def leaked_member_roles
    MemberRole
      .joins(:member)
      .joins("INNER JOIN member_roles sources ON sources.id = member_roles.inherited_from")
      .joins("INNER JOIN members source_members ON source_members.id = sources.member_id")
      .where("members.project_id  IS DISTINCT FROM source_members.project_id
           OR members.entity_type IS DISTINCT FROM source_members.entity_type
           OR members.entity_id   IS DISTINCT FROM source_members.entity_id")
  end

  describe "roles that leaked across membership scopes" do
    shared_let(:group) { create(:group, members: [user]) }
    shared_let(:global_role) { create(:global_role) }
    shared_let(:query) { create(:project_query) }
    shared_let(:query_role) { create(:view_project_query_role) }

    let(:global_member) { Member.find_by(principal: user, entity_type: nil, project_id: nil) }
    let(:share_member) { Member.find_by(principal: user, entity: query) }

    before do
      Members::CreateService.new(user: admin)
        .call(principal: group, role_ids: [global_role.id]).on_failure { |call| raise call.message }
      Shares::CreateService.new(user: admin, contract_class: EmptyContract)
        .call(entity: query, user_id: group.id, role_ids: [query_role.id]).on_failure { |call| raise call.message }

      # The leak the fixed propagation used to produce: the group's global role
      # copied onto the user's project query share.
      share_member.member_roles.create!(role: global_role,
                                        inherited_from: Member.find_by(principal: group, entity_type: nil)
                                                              .member_roles.first.id)
    end

    it "removes them and keeps the legitimate ones" do
      expect { subject }.to change(leaked_member_roles, :count).from(1).to(0)

      expect(share_member.reload.roles).to contain_exactly(query_role)
      expect(global_member.reload.roles).to contain_exactly(global_role)
    end

    it "keeps directly assigned roles that merely look similar" do
      own_role = create(:global_role)
      global_member.member_roles.create!(role: own_role)

      subject

      expect(global_member.reload.roles).to contain_exactly(global_role, own_role)
    end
  end

  describe "project less group memberships that were never mirrored" do
    shared_let(:query) { create(:project_query) }
    shared_let(:query_role) { create(:view_project_query_role) }
    shared_let(:group) { create(:group, members: [user]) }

    before do
      Shares::CreateService.new(user: admin, contract_class: EmptyContract)
        .call(entity: query, user_id: group.id, role_ids: [query_role.id]).on_failure { |call| raise call.message }

      # The state the old share creation left behind.
      Member.where(principal: user, entity: query).destroy_all
    end

    it "mirrors them onto the group's users" do
      expect { subject }.to change { Member.where(principal: user, entity: query).count }.from(0).to(1)

      member = Member.find_by(principal: user, entity: query)
      expect(member.roles).to contain_exactly(query_role)
      expect(member.member_roles.first.inherited_from).to be_present
    end

    it "is idempotent" do
      subject

      expect { ActiveRecord::Migration.suppress_messages { described_class.new.up } }
        .not_to change(Member, :count)
    end
  end
end
