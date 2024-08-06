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

RSpec.describe Authorization::UserProjectRolesQuery do
  let(:user) { build(:user) }
  let(:anonymous) { build(:anonymous) }
  let(:project) { build(:project, public: false) }
  let(:project2) { build(:project, public: false) }
  let(:public_project) { build(:project, public: true) }
  let(:work_package) { build(:work_package, project:) }
  let(:role) { build(:project_role) }
  let(:role2) { build(:project_role) }
  let(:wp_role) { build(:work_package_role) }
  let(:anonymous_role) { build(:anonymous_role) }
  let(:non_member) { build(:non_member) }
  let(:member) { build(:member, project:, roles: [role], principal: user) }
  let(:member2) { build(:member, project: project2, roles: [role2], principal: user) }
  let(:wp_member) { build(:member, project:, roles: [wp_role], principal: user, entity: work_package) }

  describe ".query" do
    before do
      non_member.save!
      anonymous_role.save!
      user.save!
    end

    it "is a user relation" do
      expect(described_class.query(user, project)).to be_a ActiveRecord::Relation
    end

    context "with the user being a member in the project" do
      before do
        member.save!
      end

      it "is the project roles" do
        expect(described_class.query(user, project)).to match [role]
      end
    end

    context "without the user being member in the project" do
      context "with the project being private" do
        it "is empty" do
          expect(described_class.query(user, project)).to be_empty
        end
      end

      context "with the project being public" do
        it "is the non member role" do
          expect(described_class.query(user, public_project)).to contain_exactly(non_member)
        end
      end
    end

    context "with the user being anonymous" do
      context "with the project being public" do
        it "is empty" do
          expect(described_class.query(anonymous, public_project)).to contain_exactly(anonymous_role)
        end
      end

      context "without the project being public" do
        it "is empty" do
          expect(described_class.query(anonymous, project)).to be_empty
        end
      end
    end

    context "with the user being a member in two projects" do
      before do
        member.save!
        member2.save!
      end

      it "returns only the roles from the requested project" do
        expect(described_class.query(user, project)).to contain_exactly(role)
      end
    end

    context "with the user being a member of a work package of the project" do
      before { wp_member.save! }

      context "and not being a member of the project itself" do
        it { expect(described_class.query(user, project)).to be_empty }
      end

      context "and being a member of the project as well" do
        before { member.save! }

        it { expect(described_class.query(user, project)).to contain_exactly(role) }
      end
    end
  end
end
