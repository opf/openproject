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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe LdapGroups::Membership do
  describe "destroy" do
    let(:synchronized_group) { create(:ldap_synchronized_group, group:) }
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    before do
      User.system.run_given do
        synchronized_group.add_members! [user]
      end
    end

    it "is removed when the user is destroyed" do
      expect(user.ldap_groups_memberships.count).to eq 1
      membership = user.ldap_groups_memberships.first
      expect(membership.group).to eq(synchronized_group)
      expect(membership.user).to eq(user)
      expect(synchronized_group.users.count).to eq(1)

      user.destroy!
      synchronized_group.reload

      expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(synchronized_group.users.count).to eq(0)
    end
  end
end
