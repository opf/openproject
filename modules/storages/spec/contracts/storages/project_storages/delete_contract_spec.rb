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
require_module_spec_helper
require "contracts/shared/model_contract_shared_context"

RSpec.describe Storages::ProjectStorages::DeleteContract do
  include_context "ModelContract shared context"

  let(:current_user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:manage_files_in_project]) }
  let(:project) { create(:project, members: { current_user => role }) }
  let(:project_storage) { create(:project_storage, project:) }
  let(:contract) { described_class.new(project_storage, current_user) }

  # Default test setup should be valid ("happy test setup").
  # The example below was included above from "ModelContract shared context".
  # This tests works with manage_files_in_project permissions for current_user.
  it_behaves_like "contract is valid"

  # Now we remove the permissions from the user by creating a role without special perms.
  context "without manage_files_in_project permission for project" do
    # existing_role is a role _without_ the :manage_files_in_project permission
    let(:role) { create(:project_role) }

    it_behaves_like "contract is invalid"
  end

  # Generic checks that the contract is valid for valid admin, but invalid otherwise
  it_behaves_like "contract is valid for active admins and invalid for regular users"

  include_examples "contract reuses the model errors"
end
