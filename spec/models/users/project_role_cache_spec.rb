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

RSpec.describe Users::ProjectRoleCache do
  shared_let(:project) { create(:project, public: false) }
  shared_let(:other_project) { create(:project, public: false) }
  shared_let(:member_role) { create(:project_role) }
  shared_let(:other_role) { create(:project_role) }
  shared_let(:global_role) { create(:global_role) }

  subject(:cache) { described_class.new(user) }

  context "for a regular user" do
    let(:user) { create(:user, member_with_roles: { project => member_role }, global_roles: [global_role]) }

    it "returns the roles of the user's membership" do
      expect(cache.fetch(project)).to contain_exactly(member_role)
    end

    it "returns no roles in a private project the user is not a member of" do
      expect(cache.fetch(other_project)).to be_empty
    end

    it "returns the user's global roles for the global context" do
      expect(cache.fetch(nil)).to contain_exactly(global_role)
    end

    context "with a public project the user is not a member of" do
      let!(:non_member_role) { create(:non_member) }

      before { other_project.update!(public: true) }

      it "returns the non-member role" do
        expect(cache.fetch(other_project)).to contain_exactly(non_member_role)
      end
    end

    context "with the project being archived" do
      before { project.update!(active: false) }

      it "returns no roles" do
        expect(cache.fetch(project)).to be_empty
      end
    end

    context "with the project currently being archived" do
      before { project.active = false }

      it "returns the roles of the user's membership" do
        expect(cache.fetch(project)).to contain_exactly(member_role)
      end
    end

    it "caches the roles per context", :aggregate_failures do
      allow(Authorization).to receive(:roles).and_call_original

      2.times { cache.fetch(project) }
      cache.fetch(other_project)

      expect(Authorization).to have_received(:roles).with(user, project).once
      expect(Authorization).to have_received(:roles).with(user, other_project).once
    end
  end

  context "for an admin" do
    let(:user) { create(:admin) }

    it "returns all givable roles in a project" do
      expect(cache.fetch(project)).to match_array(Role.givable)
    end

    it "returns all givable roles globally" do
      expect(cache.fetch(nil)).to match_array(Role.givable)
    end

    it "returns all givable roles in an archived project" do
      project.update!(active: false)

      expect(cache.fetch(project)).to match_array(Role.givable)
    end

    it "does not query the roles of the admin's memberships" do
      allow(Authorization).to receive(:roles)

      cache.fetch(project)

      expect(Authorization).not_to have_received(:roles)
    end

    context "when the admin is locked" do
      before { user.locked! }

      it "does not return all givable roles in a project" do
        expect(cache.fetch(project)).to be_empty
      end
    end
  end

  context "for an admin with admin privilege elevation required", with_flag: { admin_privilege_elevation: true } do
    let(:user) { create(:admin) }

    context "when the admin is not elevated" do
      it "returns no roles in a project the admin is not a member of" do
        expect(cache.fetch(project)).to be_empty
      end

      it "returns all givable roles globally" do
        expect(cache.fetch(nil)).to match_array(Role.givable)
      end

      context "with the admin being a member of the project" do
        let(:user) { create(:admin, member_with_roles: { project => member_role }) }

        it "returns the roles of the admin's membership" do
          expect(cache.fetch(project)).to contain_exactly(member_role)
        end
      end
    end

    context "when the admin is elevated in the project" do
      before { user.admin_elevation = Users::AdminElevation.in_projects([project.id]) }

      it "returns all givable roles in that project" do
        expect(cache.fetch(project)).to match_array(Role.givable)
      end

      it "returns no roles in another project" do
        expect(cache.fetch(other_project)).to be_empty
      end
    end
  end
end
