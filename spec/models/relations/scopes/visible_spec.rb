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

RSpec.describe Relations::Scopes::Visible do
  let(:from) { create(:work_package, project: project1) }
  let(:intermediary) { create(:work_package, project: project1) }
  let(:to) { create(:work_package, project: project2) }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:type) { "relates" }
  let!(:relation1) { create(:relation, from:, to: intermediary, relation_type: type) }
  let!(:relation2) { create(:relation, from: intermediary, to:, relation_type: type) }
  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:member_project1) do
    create(:member,
           project: project1,
           user:,
           roles: [role])
  end

  let(:member_project2) do
    create(:member,
           project: project2,
           user:,
           roles: [role])
  end

  describe ".visible" do
    context "when the user can see all work packages" do
      before do
        member_project1
        member_project2
      end

      it "returns the relations" do
        expect(Relation.visible(user))
          .to contain_exactly(relation1, relation2)
      end
    end

    context "when the user can see only the work packages in one project" do
      before do
        member_project1
      end

      it "returns the relation within the one project" do
        expect(Relation.visible(user))
          .to contain_exactly(relation1)
      end
    end

    context "when the user can see only the to work packages" do
      before do
        member_project2
      end

      it "does not return any relation (as the relation points outside the project)" do
        expect(Relation.visible(user))
          .to be_empty
      end
    end
  end
end
