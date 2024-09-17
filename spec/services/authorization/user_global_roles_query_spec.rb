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

RSpec.describe Authorization::UserGlobalRolesQuery do
  let(:user) { build(:user) }
  let(:anonymous) { build(:anonymous) }
  let(:project) { build(:project, public: false) }
  let(:project2) { build(:project, public: false) }
  let(:public_project) { build(:project, public: true) }
  let(:role) { build(:project_role) }
  let(:role2) { build(:project_role) }
  let(:anonymous_role) { build(:anonymous_role) }
  let(:non_member) { build(:non_member) }
  let(:member) do
    build(:member, project:,
                   roles: [role],
                   principal: user)
  end
  let(:member2) do
    build(:member, project: project2,
                   roles: [role2],
                   principal: user)
  end
  let(:global_permission) { OpenProject::AccessControl.permissions.find(&:global?) }
  let(:global_role) do
    build(:global_role,
          permissions: [global_permission.name])
  end
  let(:global_member) do
    build(:global_member,
          principal: user,
          roles: [global_role])
  end
  let(:work_package_permission) { [:edit_work_packages] }
  let(:work_package_editor_role) { create(:work_package_role, permissions: work_package_permission) }
  let(:work_package) { create(:work_package, project:) }
  let(:work_package_member) do
    build(:member, entity: work_package, project: work_package.project, roles: [work_package_editor_role], principal: user)
  end

  describe ".query" do
    before do
      non_member.save!
      anonymous_role.save!
      user.save!
    end

    it "is a user relation" do
      expect(described_class.query(user, project)).to be_a ActiveRecord::Relation
    end

    context "with the user being a member in a project" do
      before do
        member.save!
      end

      it "is the member and non member role" do
        expect(described_class.query(user)).to contain_exactly(role, non_member)
      end
    end

    context "with the user being a member in two projects" do
      before do
        member.save!
        member2.save!
      end

      it "is both member and the non member role" do
        expect(described_class.query(user)).to contain_exactly(role, role2, non_member)
      end
    end

    context "without the user being a member in a project" do
      it "is the non member role" do
        expect(described_class.query(user)).to contain_exactly(non_member)
      end
    end

    context "with the user being anonymous" do
      it "is the anonymous role" do
        expect(described_class.query(anonymous)).to contain_exactly(anonymous_role)
      end
    end

    context "with the user having a global role" do
      before do
        global_member.save!
      end

      it "is the global role and non member role" do
        expect(described_class.query(user)).to contain_exactly(global_role, non_member)
      end
    end

    context "with the user having a global role and a member role" do
      before do
        member.save!
        global_member.save!
      end

      it "is the global role, member role and non member role" do
        expect(described_class.query(user)).to contain_exactly(global_role, role, non_member)
      end
    end

    context "with the user having a global role, a member role and a work package role" do
      before do
        member.save!
        global_member.save!
        work_package_member.save!
      end

      it "is the global role, member role and non member role" do
        expect(described_class.query(user)).to contain_exactly(global_role, role, non_member)
      end
    end
  end
end
