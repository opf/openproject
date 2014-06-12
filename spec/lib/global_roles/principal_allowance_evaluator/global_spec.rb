#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.dirname(__FILE__) + '/../../../spec_helper'

describe OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global do

  let(:klass) { OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global }
  let(:user) { FactoryGirl.build(:user) }
  let(:filter) { klass.new user }
  let(:member) { FactoryGirl.build(:member) }
  let(:principal_role) { FactoryGirl.build(:principal_role,
                                       :role => role) }
  let(:principal_role2) { FactoryGirl.build(:principal_role) }
  let(:role) { FactoryGirl.build(:global_role) }
  let(:project) { FactoryGirl.build(:project) }

  describe :granted_for_project? do
    it { expect(filter.granted_for_project?(member, :action, project)).to be_falsey }
  end

  describe :denied_for_project? do
    it { expect(filter.denied_for_project?(member, :action, project)).to be_falsey }
  end

  describe :granted_for_global? do
    describe "WHEN checking a Member" do
      it { expect(filter.granted_for_global?(member, :action, {})).to be_falsey }
    end

    describe "WHEN checking a PrincipalRole
              WHEN the PrincipalRole has a Role that is allowed the action" do
      before do
        role.permissions = [:action]
      end

      it { expect(filter.granted_for_global?(principal_role, :action, {})).to be_truthy }
    end

    describe "WHEN checking a PrincipalRole
              WHEN the PrincipalRole has a Role that is not allowed the action" do
      it { expect(filter.granted_for_global?(principal_role, :action, {})).to be_falsey }
    end
  end

  describe :denied_for_global? do
    it { expect(filter.denied_for_global?(principal_role, :action, {})).to be_falsey }
  end

  describe :project_granting_candidates do
    it { expect(filter.project_granting_candidates(project)).to match_array([]) }
  end

  describe :global_granting_candidates do
    describe "WHEN the user has a PrincipalRole assigned" do
      before do
        user.principal_roles = [principal_role]
      end

      it { filter.global_granting_candidates =~ [principal_role] }
    end

    describe "WHEN the user has multiple PrincipalRole assigned" do
      before do
        user.principal_roles = [principal_role, principal_role2]
      end

      it { filter.global_granting_candidates =~ [principal_role, principal_role2] }
    end

    describe "WHEN the user has no PrincipalRoles assigned" do
      it { filter.global_granting_candidates =~ [] }
    end
  end
end
