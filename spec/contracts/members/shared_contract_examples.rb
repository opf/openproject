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
require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "member contract" do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user, admin: current_user_admin) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project: member_project) if member_project
    end
  end

  let(:member_project) do
    build_stubbed(:project)
  end
  let(:member_roles) do
    [role]
  end
  let(:member_principal) do
    build_stubbed(:user)
  end
  let(:role) do
    build_stubbed(:project_role)
  end
  let(:permissions) { [:manage_members] }
  let(:current_user_admin) { false }

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  describe "validation" do
    shared_examples "is valid" do
      it "is valid" do
        expect_valid(true)
      end
    end

    it_behaves_like "is valid"

    context "if the roles are nil" do
      let(:member_roles) { [] }

      it "is invalid" do
        expect_valid(false, roles: %i(role_blank))
      end
    end

    context "if any role is not assignable (e.g. builtin)" do
      let(:member_roles) do
        [build_stubbed(:project_role), build_stubbed(:anonymous_role)]
      end

      it "is invalid" do
        expect_valid(false, roles: %i(ungrantable))
      end
    end

    context "if the user lacks :manage_members permission in the project" do
      let(:permissions) { [:view_members] }

      it "is invalid" do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end

    context "if the project is nil (global membership)" do
      let(:member_project) { nil }
      let(:role) do
        build_stubbed(:global_role)
      end

      context "if the user is no admin" do
        it "is invalid" do
          expect_valid(false, project: %i(blank))
        end
      end

      context "if the user is admin and the role is global" do
        let(:current_user_admin) { true }

        it_behaves_like "is valid"
      end

      context "if the role is not a global role" do
        let(:current_user_admin) { true }
        let(:role) do
          build_stubbed(:project_role)
        end

        it "is invalid" do
          expect_valid(false, roles: %i(ungrantable))
        end
      end
    end

    context "if the project is set to one not being manageable by the user" do
      let(:permissions) { [] }

      it "is invalid" do
        expect_valid(false, project: %i(invalid))
      end
    end
  end

  describe "principal" do
    it "returns the member's principal" do
      expect(contract.principal)
        .to eql(member.principal)
    end
  end

  describe "project" do
    it "returns the member's project" do
      expect(contract.project)
        .to eql(member.project)
    end
  end

  include_examples "contract reuses the model errors"
end
