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

RSpec.describe Queries::Members::MemberQuery, "Integration" do
  let(:instance) { described_class.new }

  current_user { user }

  subject { instance.results }

  context "with two groups in a project" do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:role) { create(:project_role, permissions: %i[view_members manage_members]) }
    let!(:group1) { create(:group, name: "A", member_with_roles: { project => role }, members: [user]) }
    let!(:group2) { create(:group, name: "B", member_with_roles: { project => role }, members: [user]) }

    it "only returns one user when filtering for one group (Regression #45331)" do
      instance.where "project_id", "=", [project.id.to_s]
      instance.where "group", "=", [group1.id.to_s]

      expect(subject.count).to eq 1
      expect(subject.first.user_id).to eq user.id
    end
  end

  context "with a project and a work package membership" do
    let(:project) { create(:project) }
    let(:work_package) { create(:work_package, project:) }
    let(:user) { create(:user) }
    let(:role) { create(:project_role, permissions: %i[manage_members view_shared_work_packages]) }
    let(:wp_role) { create(:work_package_role) }
    let!(:project_membership) { create(:member, principal: user, project:, roles: [role]) }
    let!(:wp_membership) { create(:member, principal: user, project:, entity: work_package, roles: [wp_role]) }

    it "returns both, the project membership and the workPackage membership" do
      expect(subject.count).to eq(2)
      expect(subject.first).to have_attributes(
        project:,
        entity: work_package,
        principal: user
      )
      expect(subject.second).to have_attributes(
        project:,
        entity: nil,
        principal: user
      )
    end
  end
end
