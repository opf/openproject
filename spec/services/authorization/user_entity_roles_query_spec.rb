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

RSpec.describe Authorization::UserEntityRolesQuery do
  let(:user) { build(:user) }
  let(:project) { build(:project, public: false) }
  let(:work_package) { build(:work_package, project:) }
  let(:work_package2) { build(:work_package, project:) }
  let(:role) { build(:project_role) }
  let(:wp_role) { build(:work_package_role) }
  let(:other_wp_role) { build(:work_package_role) }
  let(:non_member) { build(:non_member) }
  let(:member) { build(:member, project:, roles: [wp_role], principal: user, entity: work_package) }
  let(:project_member) { build(:member, project:, roles: [role], principal: user) }
  let(:other_member) { build(:member, project:, roles: [other_wp_role], principal: user, entity: work_package2) }

  describe ".query" do
    before do
      non_member.save!
      user.save!
    end

    it "is a relation" do
      expect(described_class.query(user, work_package)).to be_a ActiveRecord::Relation
    end

    context "with the user being a member of the work package" do
      before do
        member.save!
      end

      it "returns the work package role" do
        expect(described_class.query(user, work_package)).to contain_exactly(wp_role)
      end

      context "when the user also has a membership with a different role on another work package" do
        before do
          other_member.save!
        end

        it "does not include the second role" do
          expect(described_class.query(user, work_package)).not_to include(other_wp_role)
        end
      end

      context "when the user also has a membership with a different role on the project" do
        before do
          project_member.save!
        end

        it "does not include the second role" do
          expect(described_class.query(user, work_package)).not_to include(role)
        end
      end
    end

    context "without the user being member in the work package" do
      it "is empty" do
        expect(described_class.query(user, work_package)).to be_empty
      end
    end
  end
end
