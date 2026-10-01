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

RSpec.describe Departments::AddUserService do
  let(:admin) { create(:admin) }
  let(:user_to_add) { create(:user) }

  before do
    allow(Notifications::GroupMemberAlteredJob).to receive(:perform_later)
  end

  describe "#call" do
    context "when user is not in any department" do
      let!(:department) { create(:department) }

      it "adds the user successfully" do
        result = described_class.new(department, user: admin).call(user_id: user_to_add.id)

        expect(result).to be_success
        expect(department.reload.users).to include(user_to_add)
      end
    end

    context "when user is already in the same department" do
      let!(:department) { create(:department, members: [user_to_add]) }

      it "succeeds (idempotent)" do
        result = described_class.new(department, user: admin).call(user_id: user_to_add.id)

        expect(result).to be_success
        expect(department.reload.users).to include(user_to_add)
      end
    end

    context "when user is in a different department" do
      let!(:department_a) { create(:department, members: [user_to_add]) }
      let!(:department_b) { create(:department) }

      context "without remove_from_previous_department flag" do
        it "returns failure with the existing department" do
          result = described_class.new(department_b, user: admin).call(user_id: user_to_add.id)

          expect(result).to be_failure
          expect(result.result).to eq(department_a)
        end

        it "does not add the user to the new department" do
          described_class.new(department_b, user: admin).call(user_id: user_to_add.id)

          expect(department_b.reload.users).not_to include(user_to_add)
        end

        it "does not remove the user from the old department" do
          described_class.new(department_b, user: admin).call(user_id: user_to_add.id)

          expect(department_a.reload.users).to include(user_to_add)
        end
      end

      context "with remove_from_previous_department flag" do
        it "moves the user successfully" do
          result = described_class.new(department_b, user: admin).call(user_id: user_to_add.id,
                                                                       remove_from_previous_department: true)

          expect(result).to be_success
          expect(department_b.reload.users).to include(user_to_add)
          expect(department_a.reload.users).not_to include(user_to_add)
        end
      end
    end

    context "when user is in a regular (non-department) group" do
      let!(:regular_group) { create(:group, members: [user_to_add]) }
      let!(:department) { create(:department) }

      it "adds the user without conflict" do
        result = described_class.new(department, user: admin).call(user_id: user_to_add.id)

        expect(result).to be_success
        expect(department.reload.users).to include(user_to_add)
        expect(regular_group.reload.users).to include(user_to_add)
      end
    end

    context "when user_id is passed as a string" do
      let!(:department) { create(:department) }

      it "handles string user_id" do
        result = described_class.new(department, user: admin).call(user_id: user_to_add.id.to_s)

        expect(result).to be_success
        expect(department.reload.users).to include(user_to_add)
      end
    end

    context "when called by a non-admin user" do
      let(:regular_user) { create(:user) }
      let!(:department) { create(:department) }

      it "returns failure" do
        result = described_class.new(department, user: regular_user).call(user_id: user_to_add.id)

        expect(result).to be_failure
      end
    end
  end
end
