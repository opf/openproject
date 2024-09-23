# -- copyright
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
# ++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "work package member contract" do
  include_context "ModelContract shared context"
  let(:current_user) { build_stubbed(:user, admin: current_user_admin) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project: member_project) if member_project
    end
  end

  let(:member_entity) do
    build_stubbed(:work_package)
  end
  let(:member_project) do
    member_entity.project
  end
  let(:member_roles) do
    [role]
  end
  let(:member_principal) do
    build_stubbed(:user)
  end
  let(:role) do
    build_stubbed(:view_work_package_role)
  end
  let(:permissions) { [:share_work_packages] }
  let(:current_user_admin) { false }

  describe "validation" do
    it_behaves_like "contract is valid"

    context "if the roles are nil" do
      let(:member_roles) { [] }

      it_behaves_like "contract is invalid", roles: :role_blank
    end

    context "if any role is not assignable (e.g. builtin)" do
      let(:member_roles) do
        [build_stubbed(:project_role)]
      end

      it_behaves_like "contract is invalid", roles: :ungrantable
    end

    context "if the principal is the current user" do
      let(:member_principal) { current_user }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "if more than one non-inherited role is assigned" do
      let(:member_roles) do
        [build_stubbed(:view_work_package_role), build_stubbed(:comment_work_package_role)]
      end

      it_behaves_like "contract is invalid", roles: :more_than_one
    end

    context "if the user lacks :share_work_packages permission in the project" do
      # This permission would work for a project member.
      let(:permissions) { [:manage_members] }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  include_examples "contract reuses the model errors"
end
