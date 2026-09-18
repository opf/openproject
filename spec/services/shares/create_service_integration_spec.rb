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

RSpec.describe Shares::CreateService, "integration", type: :model do
  subject(:service_call) do
    described_class
      .new(user: current_user, contract_class: EmptyContract)
      .call(entity:, user_id: group.id, role_ids: [role.id])
  end

  shared_let(:current_user) { create(:admin) }
  shared_let(:users) { create_list(:user, 2) }
  shared_let(:group) { create(:group, members: users) }

  context "with a work package" do
    shared_let(:project) { create(:project) }
    shared_let(:entity) { create(:work_package, project:) }
    shared_let(:role) { create(:view_work_package_role) }

    it "is successful" do
      expect(service_call).to be_success
    end

    it "shares the work package with the users already in the group" do
      service_call

      users.each do |user|
        expect(Member.find_by(principal: user, entity:)&.roles).to contain_exactly(role)
      end
    end
  end

  context "with a project query" do
    shared_let(:entity) { create(:project_query) }
    shared_let(:role) { create(:view_project_query_role) }

    it "is successful" do
      expect(service_call).to be_success
    end

    it "shares the project query with the users already in the group" do
      service_call

      users.each do |user|
        expect(Member.find_by(principal: user, entity:)&.roles).to contain_exactly(role)
      end
    end

    it "does not touch the users' global memberships" do
      global_role = create(:global_role)
      users.each { |user| create(:global_member, principal: user, roles: [global_role]) }

      service_call

      users.each do |user|
        expect(Member.find_by(principal: user, entity_type: nil).roles).to contain_exactly(global_role)
      end
    end
  end
end
