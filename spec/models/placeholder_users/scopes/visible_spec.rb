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

RSpec.describe PlaceholderUsers::Scopes::Visible do
  describe ".visible" do
    shared_let(:project) { create(:project) }
    shared_let(:other_project) { create(:project) }
    shared_let(:role) { create(:project_role, permissions: %i[manage_members]) }

    shared_let(:other_project_placeholder) do
      create(:placeholder_user, member_with_roles: { other_project => role })
    end
    shared_let(:global_placeholder) { create(:placeholder_user) }

    subject { PlaceholderUser.visible.to_a }

    context "when user has manage_members permission" do
      current_user { create(:user, member_with_roles: { project => role }) }

      it "sees all users" do
        expect(subject).to contain_exactly(other_project_placeholder, global_placeholder)
      end
    end

    context "when user has no manage_members permission, but it is in other project" do
      current_user { create(:user, member_with_permissions: { other_project => %i[view_work_packages] }) }

      it "sees the other user in the same project" do
        expect(subject).to contain_exactly(other_project_placeholder)
      end
    end

    context "when user has no permission" do
      current_user { create(:user) }

      it "sees nothing" do
        expect(subject).to be_empty
      end
    end
  end
end
