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

require_relative "../spec_helper"

RSpec.describe Budget, ".visible" do
  shared_let(:member_project) { create(:project, enabled_module_names: %w[budgets]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[budgets]) }
  shared_let(:member_budget) { create(:budget, project: member_project) }
  shared_let(:other_budget) { create(:budget, project: other_project) }

  subject { described_class.visible(user) }

  context "for a member with the permission to view budgets" do
    let(:user) { create(:user, member_with_permissions: { member_project => [:view_budgets] }) }

    it { is_expected.to contain_exactly(member_budget) }

    it "keeps the visibility when merged with a condition on the projects" do
      expect(subject.joins(:project).merge(Project.where(id: other_project.id))).to be_empty
    end
  end

  context "for an admin" do
    let(:user) { create(:admin) }

    it { is_expected.to contain_exactly(member_budget, other_budget) }
  end

  context "for an admin with admin privilege elevation required", with_flag: { admin_privilege_elevation: true } do
    let(:user) { create(:admin, member_with_permissions: { member_project => [:view_budgets] }) }

    context "when not elevated" do
      it { is_expected.to contain_exactly(member_budget) }
    end

    context "when elevated in another project" do
      before { user.admin_elevation = Users::AdminElevation.in_projects([other_project.id]) }

      it { is_expected.to contain_exactly(member_budget, other_budget) }
    end
  end
end
