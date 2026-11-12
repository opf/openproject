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

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizedDepartment do
  let(:user) { create(:user) }
  let(:department) { create(:department, lastname: "Frontend") }
  let(:tree) { create(:ldap_synchronized_tree) }
  let!(:synchronized_department) do
    create(:ldap_synchronized_department, synchronized_tree: tree, group: department)
  end

  before { synchronized_department.add_members!([user]) }

  describe "destroying the mapping" do
    it "keeps the department and its members, dropping only the tracking record" do
      expect { synchronized_department.destroy }
        .to change(LdapDepartments::Membership, :count).by(-1)

      expect(Group.exists?(department.id)).to be(true)
      expect(department.reload.users).to include(user)
    end
  end

  describe "destroying the parent tree" do
    it "unlinks its departments while keeping them and their members" do
      expect { tree.destroy }
        .to change(described_class, :count).by(-1)
        .and change(LdapDepartments::Membership, :count).by(-1)

      expect(Group.exists?(department.id)).to be(true)
      expect(department.reload.users).to include(user)
    end
  end
end
