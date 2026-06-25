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

RSpec.describe Departments::RemoveUserService do
  let(:admin) { create(:admin) }
  let(:member) { create(:user) }

  before do
    allow(Notifications::GroupMemberAlteredJob).to receive(:perform_later)
  end

  describe "#call" do
    context "when the user is a member of the department" do
      let!(:department) { create(:department, members: [member]) }

      it "removes the user from the department" do
        result = described_class.new(department, user: admin).call(user_id: member.id)

        expect(result).to be_success
        expect(department.reload.users).not_to include(member)
      end
    end

    context "when the department is managed by LDAP" do
      let!(:department) { create(:department, members: [member]) }

      before { allow(department).to receive(:ldap_managed?).and_return(true) }

      it "rejects the removal" do
        result = described_class.new(department, user: admin).call(user_id: member.id)

        expect(result).to be_failure
        expect(result.errors.symbols_for(:base)).to include(:user_in_ldap_managed_department)
        expect(department.reload.users).to include(member)
      end
    end
  end
end
